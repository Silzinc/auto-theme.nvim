use std::path::PathBuf;

use anyhow::{Result, anyhow};

pub(crate) fn get(_dark_mode: bool) -> Result<PathBuf> {
  Err(anyhow!(
    "Wallpaper detection: your operating system is not supported."
  ))
}
