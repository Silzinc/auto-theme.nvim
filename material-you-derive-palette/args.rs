use std::collections::HashMap;

use anyhow::anyhow;

use mlua::{Error as LuaError, FromLua, Lua, Result as LuaResult, Value as LuaValue};

use crate::colors::{MaterialScheme, Palette};

#[derive(Debug, Clone)]
pub(crate) struct Args {
  /// Palette to derive colors from
  pub(crate) base_palette: Palette,

  /// Whether dark mode is enabled
  pub(crate) dark_mode: bool,

  /// Map to override colors in the palette with certain material entries
  pub(crate) material_dispatch: HashMap<String, String>,

  /// Generate colorscheme from image
  pub(crate) img: Option<String>,

  /// Bitmap image size
  pub(crate) size: u32,

  /// Generate colorscheme from color (ignored if path is set)
  pub(crate) color: Option<String>,

  /// Material scheme to use
  pub(crate) scheme: MaterialScheme,

  /// (0-1) Color hue shift towards accent
  pub(crate) harmony: f64,

  /// (0-180) Max threshold angle to limit color hue shift
  pub(crate) harmonize_threshold: f64,

  /// (0-1) Make foreground more different from the background
  pub(crate) fg_boost: f64,
  // Shift background or foreground towards accent
  // pub(crate) blend_bg_fg: bool,
}

impl Args {
  pub(crate) fn new(
    base_palette: Palette,
    dark_mode: bool,
    material_dispatch: HashMap<String, String>,
    img: Option<String>,
    size: u32,
    color: Option<String>,
    scheme: MaterialScheme,
    harmony: f64,
    harmonize_threshold: f64,
    fg_boost: f64,
  ) -> Self {
    Self {
      base_palette,
      dark_mode,
      material_dispatch,
      img,
      size,
      color,
      scheme,
      harmony,
      harmonize_threshold,
      fg_boost,
    }
  }
}

impl FromLua for Args {
  fn from_lua(value: LuaValue, _lua: &Lua) -> LuaResult<Self> {
    let LuaValue::Table(table) = value else {
      return Err(
        anyhow!(
          "rust function expected a lua table, got a {}",
          value.type_name()
        )
        .into(),
      );
    };

    macro_rules! check {
      ($param:ident) => {
        table.get(stringify!($param)).map_err(|_| {
          LuaError::from(anyhow!(
            "failed to convert {} into rust type",
            stringify!($param)
          ))
        })?
      };
    }

    Ok(Self::new(
      check!(base_palette),
      check!(dark_mode),
      check!(material_dispatch),
      check!(img),
      check!(size),
      check!(color),
      check!(scheme),
      check!(harmony),
      check!(harmonize_threshold),
      check!(fg_boost),
    ))
  }
}
