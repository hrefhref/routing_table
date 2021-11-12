use std::sync::Mutex;
use rustler::{resource::ResourceArc, NifResult, NifRecord, NifUntaggedEnum,
              Encoder, Env, Term, types::tuple::make_tuple};

mod tree_bitmap;
use tree_bitmap::TreeBitmap;

struct TableResource {
    pub tree: Mutex<TreeBitmap<u32>>
}

mod atoms {
    rustler::atoms! {
        ok,
        nil,
        error
    }
}

trait Address {
    fn nibbles(self) -> Nibbles;
    fn mask(self, masklen: u32) -> Self;
}

#[derive(NifUntaggedEnum, Clone)]
enum AddrTuple {
    V4(TupleV4),
    V6(TupleV6)
}

impl Address for AddrTuple {
    fn nibbles(self) -> Nibbles {
        match self {
            AddrTuple::V4(tuple_v4) => tuple_v4.nibbles(),
            AddrTuple::V6(tuple_v6) => tuple_v6.nibbles()
        }
    }
    fn mask(self, masklen: u32) -> Self {
        match self {
            AddrTuple::V4(tuple_v4) => AddrTuple::V4(tuple_v4.mask(masklen)),
            AddrTuple::V6(tuple_v6) => AddrTuple::V6(tuple_v6.mask(masklen))
        }
    }
}

#[derive(Debug, NifRecord, Clone)]
#[tag = "inet4"]
struct TupleV4 {
    pub a: u8,
    pub b: u8,
    pub c: u8,
    pub d: u8
}

enum Nibbles {
    V4([u8; 8]),
    V6([u8; 32])
}

impl TupleV4 {
    pub fn new(a1: u8, a2: u8, a3: u8, a4: u8) -> Self {
        TupleV4 { a: a1, b: a2, c: a3, d: a4 }
    }
    pub fn from(num: u32) -> Self {
        TupleV4 {
            a: (num >> 24) as u8,
            b: (num >> 16) as u8,
            c: (num >> 8) as u8,
            d: num as u8,
        }
    }
}

impl Address for TupleV4 {
    fn nibbles(self) -> Nibbles {
        let mut ret: [u8; 8] = [0; 8];
        let bytes: [u8; 4] = [self.a, self.b, self.c, self.d];
        for (i, byte) in bytes.iter().enumerate() {
            ret[i * 2] = byte >> 4;
            ret[i * 2 + 1] = byte & 0xf;
        }
        Nibbles::V4(ret)
    }

    fn mask(self, masklen: u32) -> Self {
        debug_assert!(masklen <= 32);
        let ip = u32::from(self);
        let masked = match masklen {
            0 => 0,
            n => ip & (!0 << (32 - n)),
        };
        TupleV4::from(masked)
    }

}
impl ::std::convert::From<TupleV4> for u32 {
    fn from(a: TupleV4) -> u32 {
        (a.a as u32) << 24
            | (a.b as u32) << 16
            | (a.c as u32) << 8
            | (a.d as u32) << 0
    }
}

#[derive(Debug, NifRecord, Clone)]
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

impl TupleV6 {

    fn new(a1: u16, a2: u16, a3: u16, a4: u16, a5: u16, a6: u16, a7: u16, a8: u16) -> Self {
        TupleV6 { a1: a1, a2, a3: a3, a4: a4, a5: a5, a6: a6, a7: a7, a8: a8 }
    }

    fn octets(self) -> [u8; 16] {
        [
            (self.a1 >> 8) as u8,
            self.a1 as u8,
            (self.a2 >> 8) as u8,
            self.a2 as u8,
            (self.a3 >> 8) as u8,
            self.a3 as u8,
            (self.a4 >> 8) as u8,
            self.a4 as u8,
            (self.a5 >> 8) as u8,
            self.a5 as u8,
            (self.a6 >> 8) as u8,
            self.a6 as u8,
            (self.a7 >> 8) as u8,
            self.a7 as u8,
            (self.a8 >> 8) as u8,
            self.a8 as u8
        ]
    }

    fn segments(self) -> [u16; 8] {
        let bytes = self.octets();
        [
            (bytes[0] as u16) << 8 | (bytes[1] as u16),
            (bytes[2] as u16) << 8 | (bytes[3] as u16),
            (bytes[4] as u16) << 8 | (bytes[5] as u16),
            (bytes[6] as u16) << 8 | (bytes[7] as u16),
            (bytes[8] as u16) << 8 | (bytes[9] as u16),
            (bytes[10] as u16) << 8 | (bytes[11] as u16),
            (bytes[12] as u16) << 8 | (bytes[13] as u16),
            (bytes[14] as u16) << 8 | (bytes[15] as u16),
        ]
    }

}

impl Address for TupleV6 {

    fn nibbles(self) -> Nibbles {
        let mut ret: [u8; 32] = [0; 32];
        let bytes = self.octets();
        for (i, byte) in bytes.iter().enumerate() {
            ret[i * 2] = byte >> 4;
            ret[i * 2 + 1] = byte & 0xf;
        }
        Nibbles::V6(ret)
    }

    fn mask(self, masklen: u32) -> Self {
        debug_assert!(masklen <= 128);
        let mut ret = self.segments();
        for i in ((masklen + 15) / 16)..8 {
            ret[i as usize] = 0;
        }
        if masklen % 16 != 0 {
            ret[masklen as usize / 16] &= !0 << (16 - (masklen % 16));
        }
        Self::new(
            ret[0], ret[1], ret[2], ret[3], ret[4], ret[5], ret[6], ret[7],
        )
    }

}

#[rustler::nif]
fn new() -> NifResult<ResourceArc<TableResource>> {
    let tree = TreeBitmap::new();
    let resource = ResourceArc::new(TableResource {
        tree: Mutex::new(tree)
    });
    Ok(resource)
}

#[rustler::nif]
fn new_with_capacity(n: usize) -> NifResult<ResourceArc<TableResource>> {
    let tree = TreeBitmap::with_capacity(n);
    let resource = ResourceArc::new(TableResource {
        tree: Mutex::new(tree)
    });
    Ok(resource)
}

#[rustler::nif]
fn length(table_resource: ResourceArc<TableResource>) -> NifResult<usize> {
    let tree = table_resource.tree.lock().unwrap();
    Ok(tree.len())
}

#[rustler::nif]
fn add<'a>(
    env: Env<'a>,
    table_resource: ResourceArc<TableResource>,
    ip: AddrTuple,
    masklen: u32,
    value: u32
) -> Term {
    let mut tree = table_resource.tree.lock().unwrap();
    let result = match ip.nibbles() {
        Nibbles::V4(nibbles) => tree.insert(&nibbles.as_ref(), masklen, value),
        Nibbles::V6(nibbles) => tree.insert(&nibbles.as_ref(), masklen, value)
    };
    if let Some(value) = result {
        make_tuple(env, &[atoms::ok().encode(env), value.encode(env)])
    } else {
        make_tuple(env, &[atoms::ok().encode(env), atoms::nil().encode(env)])
    }
}

#[rustler::nif]
fn remove<'a>(
    env: Env<'a>,
    table_resource: ResourceArc<TableResource>,
    ip: AddrTuple,
    masklen: u32
) -> Term {
    let mut tree = table_resource.tree.lock().unwrap();
    let result = match ip.nibbles() {
        Nibbles::V4(nibbles) => tree.remove(&nibbles.as_ref(), masklen),
        Nibbles::V6(nibbles) => tree.remove(&nibbles.as_ref(), masklen),
    };
    if let Some(value) = result {
        make_tuple(env, &[atoms::ok().encode(env), value.encode(env)])
    } else {
        make_tuple(env, &[atoms::ok().encode(env), atoms::nil().encode(env)])
    }
}

#[rustler::nif]
fn longest_match<'a>(
    env: Env<'a>,
    table_resource: ResourceArc<TableResource>,
    ip: AddrTuple
) -> Term {
    let tree = table_resource.tree.lock().unwrap();
    let ip2 = ip.clone();
    let result = match ip2.nibbles() {
        Nibbles::V4(nibbles) => tree.longest_match(&nibbles.as_ref()),
        Nibbles::V6(nibbles) => tree.longest_match(&nibbles.as_ref())
    };
    if let Some((bits_matched, value)) = result {
        let prefix = ip.mask(bits_matched);
        make_tuple(env, &[atoms::ok().encode(env), prefix.encode(env), bits_matched.encode(env), value.encode(env)])
    } else {
        make_tuple(env, &[atoms::ok().encode(env), atoms::nil().encode(env)])
    }
}

#[rustler::nif]
fn exact_match<'a>(
    env: Env<'a>,
    table_resource: ResourceArc<TableResource>,
    ip: AddrTuple,
    masklen: u32
) -> Term {
    let tree = table_resource.tree.lock().unwrap();
    let ip2 = ip.clone();
    let result = match ip2.nibbles() {
        Nibbles::V4(nibbles) => tree.exact_match(&nibbles.as_ref(), masklen),
        Nibbles::V6(nibbles) => tree.exact_match(&nibbles.as_ref(), masklen)
    };
    if let Some(value) = result {
        make_tuple(env, &[atoms::ok().encode(env), value.encode(env)])
    } else {
        make_tuple(env, &[atoms::ok().encode(env), atoms::nil().encode(env)])
    }
}

#[rustler::nif]
fn memory<'a>(
    env: Env<'a>,
    table_resource: ResourceArc<TableResource>
) -> Term {
    let tree = table_resource.tree.lock().unwrap();
    let (nodes, results) = tree.mem_usage();
    make_tuple(env, &[nodes.encode(env), results.encode(env)])
}

rustler::init!("Elixir.TreeBitmap.NIF",
               [new,
                new_with_capacity,
                length,
                add,
                remove,
                longest_match,
                exact_match,
                memory],
               load = on_load);

fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource!(TableResource, env);
    true
}
