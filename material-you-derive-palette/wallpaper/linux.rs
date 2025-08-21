use anyhow::{Result, anyhow, bail};
use std::{env, fs, path::PathBuf, process::Command};

use crate::utils::bug;

#[derive(Clone, Copy, Debug)]
enum SessionType {
  Kde,
  Gnome,
  Cosmic,
  Cinnamon,
  Xfce,
}

impl SessionType {
  fn get_wallpaper(&self, dark_mode: bool) -> Result<PathBuf> {
    match self {
      Self::Kde => {
        let wallp_proc = Command::new("qdbus")
          .args([
            "org.kde.plasmashell",
            "/PlasmaShell",
            "org.kde.PlasmaShell.wallpaper",
            "0",
          ])
          .output()?;
        let prefix = b"Image: ";
        let img_line = wallp_proc
          .stdout
          .split(|&b| b == b'\n')
          .find(|line| line.len() > prefix.len() && &line[..prefix.len()] == prefix)
          .ok_or(anyhow!(
            "KDE wallpaper detection: no 'Image: ' line in plasmashell configuration"
          ))?;
        let path_bytes = &img_line[prefix.len()..];
        let path_str = str::from_utf8(path_bytes).map_err(|_| {
          anyhow!("KDE wallpaper detection: path to image is not a valid utf-8 string")
        })?;
        let dir = PathBuf::from(path_str).join("contents");
        if !dir.is_dir() {
          bail!(
            "KDE wallpaper detection: '{}' is not a directory",
            dir.display()
          );
        }

        let img_finder = |path: &PathBuf| {
          macro_rules! ask {
            ($opt:expr) => {
              match $opt {
                Some(x) => x,
                None => return false,
              }
            };
          }
          let ext = ask!(ask!(path.extension()).to_str());
          let name = ask!(ask!(path.file_stem()).to_str());
          let dims: Vec<&str> = name.split('x').collect();

          dims.len() == 2
            && ask!(dims[0].parse::<u32>().ok()) > 0
            && ask!(dims[1].parse::<u32>().ok()) > 0
            && ["jpg", "jpeg", "png", "tif", "tiff"].contains(&ext)
        };

        let find_img = |d: PathBuf| {
          for entry in fs::read_dir(&d)? {
            let entry = entry?;
            let path = entry.path();
            let realpath = if path.is_symlink() {
              // if the symlink path is relative, we want to join it to the original
              let link = fs::read_link(&path)?;
              let joint = d.join(&link);
              if link.exists() { link } else { joint }
            } else {
              path.clone()
            };
            let realpath = fs::canonicalize(realpath)?;
            if realpath.metadata()?.is_file() {
              if img_finder(&path) {
                return Ok(realpath);
              }
            }
          }
          bail!(
            "KDE wallpaper detection: No valid wallpaper found at {}",
            d.display()
          );
        };

        if dark_mode {
          find_img(dir.join("images_dark")).or(find_img(dir.join("images")))
        } else {
          find_img(dir.join("images"))
        }
      }
      // TODO: TEST
      Self::Gnome => {
        let find_img = |dark: bool| -> Result<PathBuf> {
          let key = if dark {
            "picture-uri-dark"
          } else {
            "picture-uri"
          };
          let wallp_proc = Command::new("gsettings")
            .args(["get", "org.gnome.desktop.background", key])
            .output()?;
          if wallp_proc.status.code() != Some(0) {
            bail!("GNOME wallpaper detection: could not find gnome setting {key}")
          }
          Ok(PathBuf::from(
            str::from_utf8(&wallp_proc.stdout)
              .map_err(|_| {
                anyhow!("GNOME wallpaper detection: path to image is not a valid utf-8 string")
              })?
              .strip_prefix("file://")
              .ok_or(anyhow!("GNOME wallpaper detection: {key} is invalid"))?,
          ))
        };
        if dark_mode {
          find_img(true).or(find_img(false))
        } else {
          find_img(false)
        }
      }
      // TODO: TEST
      Self::Cinnamon => {
        let find_img = |dark: bool| -> Result<PathBuf> {
          let key = if dark {
            "picture-uri-dark"
          } else {
            "picture-uri"
          };
          let wallp_proc = Command::new("gsettings")
            .args(["get", "org.cinnamon.desktop.background", key])
            .output()?;
          if wallp_proc.status.code() != Some(0) {
            bail!("Cinnamon wallpaper detection: could not find cinnamon setting {key}")
          }
          Ok(PathBuf::from(
            str::from_utf8(&wallp_proc.stdout)
              .map_err(|_| {
                anyhow!("Cinnamon wallpaper detection: path to image is not a valid utf-8 string")
              })?
              .strip_prefix("file://")
              .ok_or(anyhow!("Cinnamon wallpaper detection: {key} is invalid"))?,
          ))
        };
        if dark_mode {
          find_img(true).or(find_img(false))
        } else {
          find_img(false)
        }
      }
      Self::Xfce => Err(anyhow!("XFCE wallpaper detection: not implemented")),
      Self::Cosmic => Err(anyhow!("COSMIC wallpaper detection: not implemented")),
    }
  }

  fn detect() -> Result<Self> {
    // Check usual XDG_CURRENT_DESKTOP
    // Official values found at https://specifications.freedesktop.org/menu-spec/latest/onlyshowin-registry.html
    let xdg_desktop_type = env::var("XDG_CURRENT_DESKTOP")?;
    let first_value = xdg_desktop_type
      .split(':')
      .take(1)
      .next()
      .ok_or(bug("204c76c6-280c-433b-a0a7-c9388b7a93f5"))?;
    match first_value {
      "KDE" => Ok(Self::Kde),
      "GNOME" => Ok(Self::Gnome),
      "Cinnamon" => Ok(Self::Cinnamon),
      "XFCE" => Ok(Self::Xfce),
      "COSMIC" => Ok(Self::Cosmic),
      _ => Err(anyhow!("Unsupported desktop type '{first_value}'")),
    }
  }
}

pub(crate) fn get(dark_mode: bool) -> Result<PathBuf> {
  SessionType::detect().and_then(|ses_typ| ses_typ.get_wallpaper(dark_mode))
}
