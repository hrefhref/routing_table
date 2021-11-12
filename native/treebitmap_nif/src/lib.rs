mod addrs;
mod nibbles;
mod tree_bitmap;

use addrs::{AddrTuple, Maskable};
use nibbles::Nibbles;
use rustler::{resource::ResourceArc, types::tuple::make_tuple, Encoder, Env, NifResult, Term};
use std::sync::Mutex;
use tree_bitmap::TreeBitmap;

mod atoms {
    rustler::atoms! {
        ok,
        nil
    }
}

struct TableResource {
    pub tree: Mutex<TreeBitmap<u32>>,
}

#[rustler::nif]
fn new() -> NifResult<ResourceArc<TableResource>> {
    let tree = TreeBitmap::new();
    let resource = ResourceArc::new(TableResource {
        tree: Mutex::new(tree),
    });
    Ok(resource)
}

#[rustler::nif]
fn new_with_capacity(n: usize) -> NifResult<ResourceArc<TableResource>> {
    let tree = TreeBitmap::with_capacity(n);
    let resource = ResourceArc::new(TableResource {
        tree: Mutex::new(tree),
    });
    Ok(resource)
}

#[rustler::nif]
fn length(table_resource: ResourceArc<TableResource>) -> NifResult<usize> {
    let tree = table_resource.tree.lock().unwrap();
    Ok(tree.len())
}

#[rustler::nif]
fn add(
    env: Env,
    table_resource: ResourceArc<TableResource>,
    ip: AddrTuple,
    masklen: u32,
    value: u32,
) -> Term {
    let mut tree = table_resource.tree.lock().unwrap();
    if let Some(value) = tree.insert(Nibbles::from(ip).as_ref(), masklen, value) {
        make_tuple(env, &[atoms::ok().encode(env), value.encode(env)])
    } else {
        make_tuple(env, &[atoms::ok().encode(env), atoms::nil().encode(env)])
    }
}

#[rustler::nif]
fn remove(
    env: Env,
    table_resource: ResourceArc<TableResource>,
    ip: AddrTuple,
    masklen: u32,
) -> Term {
    let mut tree = table_resource.tree.lock().unwrap();
    if let Some(value) = tree.remove(Nibbles::from(ip).as_ref(), masklen) {
        make_tuple(env, &[atoms::ok().encode(env), value.encode(env)])
    } else {
        make_tuple(env, &[atoms::ok().encode(env), atoms::nil().encode(env)])
    }
}

#[rustler::nif]
fn longest_match(env: Env, table_resource: ResourceArc<TableResource>, ip: AddrTuple) -> Term {
    let tree = table_resource.tree.lock().unwrap();
    if let Some((bits_matched, value)) = tree.longest_match(Nibbles::from(ip).as_ref()) {
        let prefix = ip.mask(bits_matched);
        make_tuple(
            env,
            &[
                atoms::ok().encode(env),
                prefix.encode(env),
                bits_matched.encode(env),
                value.encode(env),
            ],
        )
    } else {
        make_tuple(env, &[atoms::ok().encode(env), atoms::nil().encode(env)])
    }
}

#[rustler::nif]
fn exact_match(
    env: Env,
    table_resource: ResourceArc<TableResource>,
    ip: AddrTuple,
    masklen: u32,
) -> Term {
    let tree = table_resource.tree.lock().unwrap();
    if let Some(value) = tree.exact_match(Nibbles::from(ip).as_ref(), masklen) {
        make_tuple(env, &[atoms::ok().encode(env), value.encode(env)])
    } else {
        make_tuple(env, &[atoms::ok().encode(env), atoms::nil().encode(env)])
    }
}

#[rustler::nif]
fn memory(env: Env, table_resource: ResourceArc<TableResource>) -> Term {
    let tree = table_resource.tree.lock().unwrap();
    let (nodes, results) = tree.mem_usage();
    make_tuple(env, &[nodes.encode(env), results.encode(env)])
}

rustler::init!(
    "Elixir.RoutingTable.TreeBitmap",
    [
        new,
        new_with_capacity,
        length,
        add,
        remove,
        longest_match,
        exact_match,
        memory
    ],
    load = on_load
);

fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource!(TableResource, env);
    true
}
