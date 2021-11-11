use std::sync::Mutex;
use rustler::{resource::ResourceArc, NifResult, NifRecord, Encoder, Env, Term, types::atom::Atom, types::tuple::make_tuple};
//use std::net::Ipv6Addr;
use std::net::{Ipv4Addr};
use treebitmap::{IpLookupTable};

struct TableResource {
    pub table: Mutex<IpLookupTable<Ipv4Addr, u32>>
}

mod atoms {
    rustler::atoms! {
        ok,
        nil,
        error
    }
}

enum AddrTuple {
    V4(TupleV4),
    V6(TupleV6)
}

#[derive(Debug, NifRecord)]
#[tag = "inet4"]
struct TupleV4 {
    pub a: u8,
    pub b: u8,
    pub c: u8,
    pub d: u8
}

#[derive(Debug, NifRecord)]
#[tag = "inet6"]
struct TupleV6 {
    pub a1: u16,
    pub a2: u16,
    pub a3: u16,
    pub a4: u16,
    pub a5: u16,
    pub a6: u16,
    pub a7: u16,
    pub a8: u16
}

#[rustler::nif]
fn new() -> NifResult<ResourceArc<TableResource>> {
    let table = IpLookupTable::new();
    let resource = ResourceArc::new(TableResource {
      table: Mutex::new(table)
    });
    Ok(resource)
}

#[rustler::nif]
fn length(table_resource: ResourceArc<TableResource>) -> NifResult<usize> {
    let table = table_resource.table.lock().unwrap();
    Ok(table.len())
}

#[rustler::nif]
fn add(
    table_resource: ResourceArc<TableResource>,
    ipv4: TupleV4,
    masklen: u32,
    value: u32
) -> NifResult<Atom>{
    let mut table = table_resource.table.lock().unwrap();
    let addr = Ipv4Addr::new(ipv4.a, ipv4.b, ipv4.c, ipv4.d);
    table.insert(addr, masklen, value);
    Ok(atoms::ok())
}

#[rustler::nif]
fn remove(
    table_resource: ResourceArc<TableResource>,
    ipv4: TupleV4,
    masklen: u32
) -> NifResult<Atom>{
    let mut table = table_resource.table.lock().unwrap();
    let addr = Ipv4Addr::new(ipv4.a, ipv4.b, ipv4.c, ipv4.d);
    table.remove(addr, masklen);
    Ok(atoms::ok())
}

#[rustler::nif]
fn lookup<'a>(
    env: rustler::Env<'a>,
    table_resource: ResourceArc<TableResource>,
    ipv4: TupleV4
) -> Term {
    let table = table_resource.table.lock().unwrap();
    let addr = Ipv4Addr::new(ipv4.a, ipv4.b, ipv4.c, ipv4.d);
    if let Some((prefix, prefixlen, value)) = table.longest_match(addr) {
        let addr = prefix.octets();
        make_tuple(env, &[atoms::ok().encode(env), addr.encode(env), prefixlen.encode(env), value.encode(env)])
    } else {
        make_tuple(env, &[atoms::ok().encode(env), atoms::nil().encode(env)])
    }
}

rustler::init!("Elixir.TreeBitmap.NIF", [new, length, add, remove, lookup], load = on_load);

fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource!(TableResource, env);
    true
}
