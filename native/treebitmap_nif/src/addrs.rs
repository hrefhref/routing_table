use crate::nibbles::{Nibbles, NibblesV4, NibblesV6};
use rustler::{NifRecord, NifUntaggedEnum};

pub trait Maskable {
    fn mask(self, masklen: u32) -> Self;
}

#[derive(Debug, NifRecord, Copy, Clone)]
#[tag = "inet4"]
pub struct TupleV4 {
    pub a: u8,
    pub b: u8,
    pub c: u8,
    pub d: u8,
}

impl TupleV4 {
    pub fn from(num: u32) -> Self {
        TupleV4 {
            a: (num >> 24) as u8,
            b: (num >> 16) as u8,
            c: (num >> 8) as u8,
            d: num as u8,
        }
    }

    pub fn octets(&self) -> [u8; 4] {
        [self.a, self.b, self.c, self.d]
    }
}

impl Maskable for TupleV4 {
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

impl ::std::convert::From<TupleV4> for Nibbles {
    fn from(a: TupleV4) -> Nibbles {
        let mut ret: [u8; 8] = [0; 8];
        let bytes: [u8; 4] = a.octets();
        for (i, byte) in bytes.iter().enumerate() {
            ret[i * 2] = byte >> 4;
            ret[i * 2 + 1] = byte & 0xf;
        }
        Nibbles::V4(NibblesV4 { n: ret })
    }
}

impl ::std::convert::From<TupleV4> for u32 {
    fn from(a: TupleV4) -> u32 {
        (a.a as u32) << 24 | (a.b as u32) << 16 | (a.c as u32) << 8 | (a.d as u32)
    }
}

#[derive(Debug, NifRecord, Copy, Clone)]
#[tag = "inet6"]
pub struct TupleV6 {
    pub a1: u16,
    pub a2: u16,
    pub a3: u16,
    pub a4: u16,
    pub a5: u16,
    pub a6: u16,
    pub a7: u16,
    pub a8: u16,
}

impl TupleV6 {
    #[allow(clippy::too_many_arguments)]
    fn new(a1: u16, a2: u16, a3: u16, a4: u16, a5: u16, a6: u16, a7: u16, a8: u16) -> Self {
        TupleV6 {
            a1,
            a2,
            a3,
            a4,
            a5,
            a6,
            a7,
            a8,
        }
    }

    fn octets(&self) -> [u8; 16] {
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
            self.a8 as u8,
        ]
    }

    fn segments(&self) -> [u16; 8] {
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

impl Maskable for TupleV6 {
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

impl ::std::convert::From<TupleV6> for Nibbles {
    fn from(a: TupleV6) -> Nibbles {
        let mut ret: [u8; 32] = [0; 32];
        let bytes = a.octets();
        for (i, byte) in bytes.iter().enumerate() {
            ret[i * 2] = byte >> 4;
            ret[i * 2 + 1] = byte & 0xf;
        }
        Nibbles::V6(NibblesV6 { n: ret })
    }
}

#[derive(NifUntaggedEnum, Copy, Clone)]
pub enum AddrTuple {
    V4(TupleV4),
    V6(TupleV6),
}

impl Maskable for AddrTuple {
    fn mask(self, masklen: u32) -> Self {
        match self {
            AddrTuple::V4(tuple_v4) => AddrTuple::V4(tuple_v4.mask(masklen)),
            AddrTuple::V6(tuple_v6) => AddrTuple::V6(tuple_v6.mask(masklen)),
        }
    }
}

impl ::std::convert::From<AddrTuple> for Nibbles {
    fn from(a: AddrTuple) -> Nibbles {
        match a {
            AddrTuple::V4(v4) => Nibbles::from(v4),
            AddrTuple::V6(v6) => Nibbles::from(v6),
        }
    }
}
