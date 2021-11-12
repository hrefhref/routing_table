pub struct NibblesV4 {
    pub n: [u8; 8],
}
pub struct NibblesV6 {
    pub n: [u8; 32],
}

pub enum Nibbles {
    V4(NibblesV4),
    V6(NibblesV6),
}

impl AsRef<[u8]> for Nibbles {
    fn as_ref(&self) -> &[u8] {
        match self {
            Nibbles::V4(nib4) => nib4.as_ref(),
            Nibbles::V6(nib6) => nib6.as_ref(),
        }
    }
}

impl AsRef<[u8]> for NibblesV4 {
    fn as_ref(&self) -> &[u8] {
        &self.n
    }
}

impl AsRef<[u8]> for NibblesV6 {
    fn as_ref(&self) -> &[u8] {
        &self.n
    }
}
