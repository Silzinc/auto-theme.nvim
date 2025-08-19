use anyhow::{Error, anyhow};

pub(crate) fn bug(uuid: &str) -> Error {
  anyhow!("{uuid}: This error should not happen, please report")
}
