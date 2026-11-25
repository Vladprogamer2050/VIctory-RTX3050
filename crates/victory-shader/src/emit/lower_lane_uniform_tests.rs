use super::*;

#[test]
fn lane_uniform_lds_read_requires_settled_memory_and_uniform_address() {
    // Wave64 compute program lowered for a 32-lane host: all lanes write
    // their LDS element, meet at a group barrier, then inside a divergent
    // branch read the same uniform address and broadcast a scalar result.
    // A per-lane read address must not be classified as uniform.
    let make = |addr_vgpr: u32| -> Vec<u32> {
        vec![
            0xBE90_0380, // s_mov_b32 s16, 0
            0xBE91_0380, // s_mov_b32 s17, 0
            0xD834_0000, // ds_write_b32 v0, v0
            0x0000_0000,
            S_BARRIER,
            0xD760_0004, // v_readlane_b32 s4, v0, 0 (triggers wave64 exchange)
            0x0001_0100,
            0x7D88_00A0, // v_cmp_gt_u32_e32 vcc, 32, v0: half the console wave remains active
            0xBE86_246A, // s_and_saveexec_b64 s[6:7], vcc
            0xBF88_0005, // s_cbranch_execz -> restore exec
            0x7E02_0210, // v_mov_b32 v1, s16
            0xD8D8_0000, // ds_read_b32 v2, v{addr}
            0x0200_0000 | addr_vgpr,
            0x4A10_0411, // v_add_nc_u32 v8, s17, v2
            0x7E22_0508, // v_readfirstlane_b32 s17, v8
            0xBEFE_0406, // s_mov_b64 exec, s[6:7]
            0x8011_0411, // s_add_u32 s17, s17, s4 (keep s17 and s4 live)
            0x7E06_0211, // v_mov_b32 v3, s17
            S_ENDPGM,
        ]
    };
    let run = |words: &[u32]| {
        let code: Vec<u8> = words.iter().flat_map(|w| w.to_le_bytes()).collect();
        let native = NativeProgram {
            stage: HwStage::Cs,
            wave64: true,
            vgprs: 256,
            layout: vec![],
            used: vec![],
            io: StageIo::Cs(ComputeIo {
                rsrc2: 1 << 15, // 512 bytes LDS
                threads: [128, 1, 1],
            }),
            code,
        };
        let p = ir::build(&native.code, true, 256).unwrap();
        let st = structure::structure(&p).unwrap();
        let all = super::super::all_lane_blocks(&st).unwrap();
        let same = super::super::lane_uniform(&p, &st, &all);
        let loaded_uniform = p
            .blocks
            .iter()
            .flat_map(|block| &block.insts)
            .find(|instruction| instruction.name() == "ds_read_b32")
            .and_then(|instruction| instruction.write(crate::ir::Reg::V(2)))
            .is_some_and(|value| same.contains(&value));
        let res = resource::track(&p, &native.layout, native.stage, Some(&st)).unwrap();
        let io = io::raise(&p, &native).unwrap();
        let prev = super::super::TEST_HOST_WAVE.replace(Some(32));
        let out = lower(&Parts {
            native: &native,
            p: &p,
            st: &st,
            io: &io,
            res: &res,
            inputs: vec![],
            outputs: vec![],
            prims: vec![],
            mesh_stride: 0,
        });
        super::super::TEST_HOST_WAVE.set(prev);
        (out, loaded_uniform)
    };

    let (uniform_result, uniform_address) = run(&make(1));
    assert!(
        uniform_address,
        "an LDS read from a settled, uniform address must be classified as uniform"
    );
    if let Err(error) = uniform_result {
        panic!("uniform LDS read and first-lane broadcast must lower on wave32, got: {error}");
    }

    let (_, per_lane_address) = run(&make(0));
    assert!(
        !per_lane_address,
        "an LDS read from a per-lane address must remain varying"
    );
}

#[test]
fn lane_uniform_handles_v255_and_high_pair_operands() {
    // Regression test for operands ending at v255 (exclusive end 256):
    // 1. A single-word uniform v255 must still be recognised as wave-uniform.
    // 2. A 64-bit pair v[254:255] with uniform v254 and per-lane v255 shifted
    //    right by 32 copies v255 into v8 and must NOT be classified as uniform.
    let run = |body: &[u32]| {
        let mut words = vec![
            0xBE90_0380, // s_mov_b32 s16, 0
            0xBE91_0380, // s_mov_b32 s17, 0
            0xD760_0004, // v_readlane_b32 s4, v0, 0 (triggers wave64 exchange)
            0x0001_0100,
            0x7D88_0081,                           // v_cmp_gt_u32_e32 vcc, 1, v0
            0xBE86_246A,                           // s_and_saveexec_b64 s[6:7], vcc
            0xBF88_0000 | (body.len() as u32 + 1), // s_cbranch_execz -> restore exec
        ];
        words.extend_from_slice(body);
        words.extend_from_slice(&[
            0x7E22_0508, // v_readfirstlane_b32 s17, v8
            0xBEFE_0406, // s_mov_b64 exec, s[6:7]
            0x8011_0411, // s_add_u32 s17, s17, s4
            0x7E06_0211, // v_mov_b32 v3, s17
            0xD834_0000, // ds_write_b32 v0, v3
            0x0000_0300,
            S_ENDPGM,
        ]);
        let code: Vec<u8> = words.iter().flat_map(|w| w.to_le_bytes()).collect();
        let native = NativeProgram {
            stage: HwStage::Cs,
            wave64: true,
            vgprs: 256,
            layout: vec![],
            used: vec![],
            io: StageIo::Cs(ComputeIo {
                rsrc2: 1 << 15,
                threads: [128, 1, 1],
            }),
            code,
        };
        let p = ir::build(&native.code, true, 256).unwrap();
        let st = structure::structure(&p).unwrap();
        let res = resource::track(&p, &native.layout, native.stage, Some(&st)).unwrap();
        let io = io::raise(&p, &native).unwrap();
        let prev = super::super::TEST_HOST_WAVE.replace(Some(32));
        let out = lower(&Parts {
            native: &native,
            p: &p,
            st: &st,
            io: &io,
            res: &res,
            inputs: vec![],
            outputs: vec![],
            prims: vec![],
            mesh_stride: 0,
        });
        super::super::TEST_HOST_WAVE.set(prev);
        out
    };

    // Uniform v255 -> uniform v8 -> v_readfirstlane_b32 lowers on wave32.
    let uniform_v255 = [
        0x7FFE_0210, // v_mov_b32 v255, s16
        0x4A11_FE11, // v_add_nc_u32 v8, s17, v255
    ];
    if let Err(e) = run(&uniform_v255) {
        panic!("uniform v255 read must be recognised as wave-uniform, got: {e}");
    }

    // Uniform v254 + per-lane v255 -> v_lshrrev_b64 v[8:9], 32, v[254:255] -> per-lane v8.
    let varying_high = [
        0x7FFC_0210, // v_mov_b32 v254, s16
        0x7FFE_0300, // v_mov_b32 v255, v0
        0xD700_0008, // v_lshrrev_b64 v[8:9], 32, v[254:255]
        0x0003_FCA0,
    ];
    let err = run(&varying_high)
        .err()
        .expect("varying v255 high word must not be classified as uniform")
        .to_string();
    assert!(
        err.contains("a first-lane read where not every lane runs"),
        "varying v255 high word must require all lanes, got: {err}"
    );
}

/// Build a small wave64 compute program from its instruction words.
fn wave64(words: &[u32]) -> ir::Program {
    let code: Vec<u8> = words.iter().flat_map(|word| word.to_le_bytes()).collect();
    ir::build(&code, true, 8).unwrap()
}

/// DS op vdst, addr, data0 at offset zero.
const fn ds(op: u32, vdst: u32, addr: u32, data0: u32) -> [u32; 2] {
    [0x36 << 26 | op << 18, vdst << 24 | data0 << 8 | addr]
}

const V_MOV_V1_S0: u32 = 0x7E02_0200;
const S_BARRIER: u32 = 0xBF8A_0000;
const DS_WRITE_B32: u32 = 0x0D;
const DS_READ_B32: u32 = 0x36;

fn lds_read_site(p: &ir::Program) -> ((usize, usize), ir::Value) {
    for (block, instructions) in p.blocks.iter().enumerate() {
        for (index, instruction) in instructions.insts.iter().enumerate() {
            if instruction.name() == "ds_read_b32" {
                return ((block, index), instruction.write(ir::Reg::V(3)).unwrap());
            }
        }
    }
    panic!("the test program has no ds_read_b32");
}

#[test]
fn a_shared_read_at_a_uniform_address_after_a_barrier_is_uniform() {
    // Every wave writes before the group barrier; every wave then reads the
    // same scalar address. Both host halves must observe the same dword.
    let mut words = vec![V_MOV_V1_S0];
    words.extend(ds(DS_WRITE_B32, 0, 1, 2));
    words.push(S_BARRIER);
    words.extend(ds(DS_READ_B32, 3, 1, 0));
    words.push(S_ENDPGM);

    let program = wave64(&words);
    let structure = structure::structure(&program).unwrap();
    let all = super::super::all_lane_blocks(&structure).unwrap();
    let (site, loaded) = lds_read_site(&program);
    assert!(super::super::lds::settled(&program, site));
    assert!(super::super::lane_uniform(&program, &structure, &all).contains(&loaded));
}

#[test]
fn an_lds_read_without_a_barrier_or_after_a_later_write_is_not_settled() {
    // Without a barrier, another console wave may still be writing while
    // this wave reads the shared address.
    let mut words = vec![V_MOV_V1_S0];
    words.extend(ds(DS_WRITE_B32, 0, 1, 2));
    words.extend(ds(DS_READ_B32, 3, 1, 0));
    words.push(S_ENDPGM);

    let program = wave64(&words);
    let (site, loaded) = lds_read_site(&program);
    assert!(!super::super::lds::settled(&program, site));

    let structure = structure::structure(&program).unwrap();
    let all = super::super::all_lane_blocks(&structure).unwrap();
    assert!(!super::super::lane_uniform(&program, &structure, &all).contains(&loaded));

    // A later LDS write also makes the original read unsafe to call settled:
    // the second half could observe a different value from the first.
    let mut words = vec![V_MOV_V1_S0];
    words.extend(ds(DS_WRITE_B32, 0, 1, 2));
    words.push(S_BARRIER);
    words.extend(ds(DS_READ_B32, 3, 1, 0));
    words.extend(ds(DS_WRITE_B32, 0, 1, 3));
    words.push(S_ENDPGM);

    let program = wave64(&words);
    let (site, _) = lds_read_site(&program);
    assert!(!super::super::lds::settled(&program, site));
}
