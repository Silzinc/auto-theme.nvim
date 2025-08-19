use std::str::FromStr;

use anyhow::anyhow;
use material_colors::{blend, color::Argb};
use mlua::{
  Error as LuaError, IntoLua, Lua, Result as LuaResult, Table as LuaTable, Value as LuaValue,
};

use crate::{args::Args, utils::bug};

mod args;
mod colors;
mod functions;
mod utils;
mod wallpaper;

fn lua_generate_palette(lua: &Lua, args: Args) -> LuaResult<LuaTable> {
  let rs_palette = functions::generate_palette(args)?;
  match rs_palette.into_lua(lua)? {
    LuaValue::Table(palette) => Ok(palette),
    _ => Err(bug("40c5b199-4ff9-46f6-8c4b-2fc7dcfac8cd").into()),
  }
}

fn lua_blend_colors(_lua: &Lua, args: (String, String, f64)) -> LuaResult<String> {
  let c1 = Argb::from_str(&args.0)
    .map_err(|_| LuaError::from(anyhow!("invalid hexadecimal string {}", args.0)))?;
  let c2 = Argb::from_str(&args.1)
    .map_err(|_| LuaError::from(anyhow!("invalid hexadecimal string {}", args.1)))?;
  let alpha = args.2.max(0.0).min(1.0);
  Ok(format!("#{}", blend::hct_hue(c1, c2, alpha).to_hex()))
}

// NOTE: skip_memory_check greatly improves performance
// https://github.com/mlua-rs/mlua/issues/318
#[mlua::lua_module(skip_memory_check)]
fn material_you_derive_palette(lua: &Lua) -> LuaResult<LuaTable> {
  let m = lua.create_table()?;
  m.set(
    "generate_palette",
    lua.create_function(lua_generate_palette)?,
  )?;
  m.set("blend", lua.create_function(lua_blend_colors)?)?;
  Ok(m)
}
