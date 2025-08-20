use mlua::{IntoLua, Lua, Result as LuaResult, Table as LuaTable, Value as LuaValue};

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

// NOTE: skip_memory_check greatly improves performance
// https://github.com/mlua-rs/mlua/issues/318
#[mlua::lua_module(skip_memory_check)]
fn material_you_derive_palette(lua: &Lua) -> LuaResult<LuaTable> {
  let m = lua.create_table()?;
  m.set(
    "generate_palette",
    lua.create_function(lua_generate_palette)?,
  )?;
  Ok(m)
}
