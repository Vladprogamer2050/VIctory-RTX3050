use super::*;

/// Whether an LDS read sees data that has settled for every lane in the group.
pub(super) fn settled(p: &Program, read: (usize, usize)) -> bool {
    let writes = |inst: &Inst| {
        let name = inst.name();
        matches!(inst.fields, Fields::Ds { .. })
            && !(name.starts_with("ds_read")
                || name.starts_with("ds_swizzle")
                || name.starts_with("ds_permute")
                || name.starts_with("ds_bpermute")
                || name == "ds_nop")
    };
    let barrier = |inst: &Inst| inst.name() == "s_barrier";
    let mut successors = vec![Vec::new(); p.blocks.len()];
    for (block_index, block) in p.blocks.iter().enumerate() {
        for &predecessor in &block.preds {
            if predecessor < p.blocks.len() && !successors[predecessor].contains(&block_index) {
                successors[predecessor].push(block_index);
            }
        }
    }

    // A write after this read on any path (including a loop) means the two
    // host halves could observe different values.
    let after_read = (read.0, read.1 + 1);
    if reaches(
        p,
        &successors,
        after_read,
        &|block, index| writes(&p.blocks[block].insts[index]),
        None,
    ) {
        return false;
    }

    // Every earlier write that can reach the read must be separated from it
    // by a group barrier.
    for (block_index, block) in p.blocks.iter().enumerate() {
        for (instruction_index, instruction) in block.insts.iter().enumerate() {
            let is_read = |block, index| (block, index) == read;
            if writes(instruction)
                && reaches(
                    p,
                    &successors,
                    (block_index, instruction_index + 1),
                    &is_read,
                    Some(&barrier),
                )
            {
                return false;
            }
        }
    }
    true
}

/// Whether a path from a start position reaches a target before an optional
/// cut instruction. Positions use (block, instruction) indices.
fn reaches(
    p: &Program,
    successors: &[Vec<usize>],
    start: (usize, usize),
    hit: &dyn Fn(usize, usize) -> bool,
    cut: Option<&dyn Fn(&Inst) -> bool>,
) -> bool {
    let mut entered = vec![false; p.blocks.len()];
    let mut stack = vec![start];
    while let Some((block, from)) = stack.pop() {
        let mut stopped = false;
        for (index, instruction) in p.blocks[block].insts.iter().enumerate().skip(from) {
            if hit(block, index) {
                return true;
            }
            if cut.is_some_and(|cut| cut(instruction)) {
                stopped = true;
                break;
            }
        }
        if !stopped {
            for &successor in &successors[block] {
                if !entered[successor] {
                    entered[successor] = true;
                    stack.push((successor, 0));
                }
            }
        }
    }
    false
}
