use std::{collections::HashMap, str::FromStr};

use anyhow::anyhow;
use material_colors::{color::Argb, dynamic_color::Variant};
use mlua::{Error as LuaError, FromLua, IntoLua, Lua, Result as LuaResult, Value as LuaValue};

use crate::utils::bug;

#[derive(Debug, Clone, Hash)]
pub(crate) enum MaterialScheme {
  Monochrome,
  Neutral,
  TonalSpot,
  Vibrant,
  Expressive,
  Fidelity,
  Content,
  Rainbow,
  FruitSalad,
}

impl FromLua for MaterialScheme {
  fn from_lua(value: LuaValue, _: &Lua) -> LuaResult<Self> {
    Ok(match value {
      LuaValue::String(s) => match s.to_string_lossy().as_str() {
        "monochrome" => MaterialScheme::Monochrome,
        "neutral" => MaterialScheme::Neutral,
        "tonal-spot" => MaterialScheme::TonalSpot,
        "vibrant" => MaterialScheme::Vibrant,
        "expressive" => MaterialScheme::Expressive,
        "fidelity" => MaterialScheme::Fidelity,
        "content" => MaterialScheme::Content,
        "rainbow" => MaterialScheme::Rainbow,
        "fruit-salad" => MaterialScheme::FruitSalad,
        s => return Err(anyhow!("Invalid material scheme '{s}'").into()),
      },
      _ => {
        return Err(
          anyhow!(
            "Material scheme should be a string, got a {} instead",
            value.type_name()
          )
          .into(),
        );
      }
    })
  }
}

impl MaterialScheme {
  pub(crate) fn to_variant(&self) -> Variant {
    match self {
      MaterialScheme::Monochrome => Variant::Monochrome,
      MaterialScheme::Neutral => Variant::Neutral,
      MaterialScheme::TonalSpot => Variant::TonalSpot,
      MaterialScheme::Vibrant => Variant::Vibrant,
      MaterialScheme::Expressive => Variant::Expressive,
      MaterialScheme::Fidelity => Variant::Fidelity,
      MaterialScheme::Content => Variant::Content,
      MaterialScheme::Rainbow => Variant::Rainbow,
      MaterialScheme::FruitSalad => Variant::FruitSalad,
    }
  }
}

#[derive(Debug, Clone)]
pub(crate) struct Palette(pub(crate) HashMap<String, Argb>);

impl IntoLua for Palette {
  fn into_lua(self, lua: &Lua) -> LuaResult<LuaValue> {
    let table = lua.create_table()?;
    for (k, argb) in self.0.into_iter() {
      table.set(k, format!("#{}", argb.to_hex()))?;
    }
    Ok(LuaValue::Table(table))
  }
}

impl FromLua for Palette {
  fn from_lua(value: LuaValue, lua: &Lua) -> LuaResult<Self> {
    match value {
      LuaValue::Table(table) => {
        let mut map = HashMap::new();

        table.for_each(|k: LuaValue, v| {
          let k = String::from_lua(k, lua)
            .map_err(|_| LuaError::from(bug("a9a7c484-f1da-4d58-b928-5c456cd09d80")))?;

          let v = String::from_lua(v, lua).map_err(|_| {
            LuaError::from(anyhow!("invalid non-string value for dynamic_palette[{k}]",))
          })?;

          map.insert(
            k,
            Argb::from_str(&v).map_err(|_| anyhow!("Invalid hexadecimal string {v}"))?,
          );

          Ok(())
        })?;

        Ok(Self(map))
      }
      _ => Err(
        anyhow!(
          "A palette should be a table, got a {} instead",
          value.type_name()
        )
        .into(),
      ),
    }
  }
}
