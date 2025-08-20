use std::{collections::HashMap, hash::RandomState, path::PathBuf, str::FromStr};

use anyhow::anyhow;
use image::{
  AnimationDecoder, ImageFormat, ImageReader, RgbaImage,
  codecs::gif::GifDecoder,
  imageops::{FilterType, resize},
};
use material_colors::{
  color::Argb,
  hct::Hct,
  quantize::{Quantizer, QuantizerCelebi},
  score::Score,
  theme::ThemeBuilder,
  utils::math::{difference_degrees, rotate_direction, sanitize_degrees_double},
};

use crate::{args::Args, colors::Palette, wallpaper};

fn harmonize(design_color: Argb, source_color: Argb, harmony: f64, threshold: f64) -> Argb {
  let from_hct: Hct = design_color.into();
  let to_hct: Hct = source_color.into();

  let difference_degrees = difference_degrees(from_hct.get_hue(), to_hct.get_hue());
  let rotation_degrees = (difference_degrees * harmony).min(threshold);

  let output_hue = sanitize_degrees_double(rotation_degrees.mul_add(
    rotate_direction(from_hct.get_hue(), to_hct.get_hue()),
    from_hct.get_hue(),
  ));

  Hct::from(output_hue, from_hct.get_chroma(), from_hct.get_tone()).into()
}

fn boost_chroma_tone(argb: Argb, chroma: Option<f64>, tone: Option<f64>) -> Argb {
  let hct: Hct = argb.into();
  Hct::from(
    hct.get_hue(),
    hct.get_chroma() * chroma.unwrap_or(1.0),
    hct.get_tone() * tone.unwrap_or(1.0),
  )
  .into()
}

fn calculate_optimal_size(w: u32, h: u32, bitmap_size: u32) -> (u32, u32) {
  let scale = (bitmap_size * bitmap_size) as f64 / (w * h) as f64;
  if scale > 1.0 {
    (w, h)
  } else {
    let nw = (w as f64 * scale).round().max(1.0);
    let nh = (h as f64 * scale).round().max(1.0);
    (nw as u32, nh as u32)
  }
}

pub(crate) fn generate_palette(args: Args) -> anyhow::Result<Palette> {
  let variant = args.scheme.to_variant();

  let img_path = if let Some(img) = args.img {
    Some(if &img == "wallpaper" {
      wallpaper::get(args.dark_mode)?
    } else {
      PathBuf::from(img)
    })
  } else {
    None
  };

  let argb = if let Some(path) = img_path {
    let image_reader = ImageReader::open(&path)?;

    let mut image: RgbaImage = if image_reader.format() == Some(ImageFormat::Gif) {
      let mut frames = GifDecoder::new(image_reader.into_inner())?.into_frames();
      let first_frame = frames.next().ok_or(anyhow!(
        "GIF file at {} has no readable frame.",
        path.display()
      ))??;
      first_frame.into_buffer().into()
    } else {
      image_reader.decode()?.into()
    };

    let (w, h) = image.dimensions();
    let (nw, nh) = calculate_optimal_size(w, h, args.size);
    if nw < w || nh < h {
      image = resize(&image, nw, nh, FilterType::Lanczos3);
    }

    let pixel_array = image
      .pixels()
      .map(|pixel| {
        let [a, r, g, b] = u32::from_be_bytes(pixel.0).rotate_right(8).to_be_bytes();
        Argb::new(a, r, g, b)
      })
      .collect::<Vec<Argb>>();
    let colors = QuantizerCelebi::quantize(&pixel_array, 128);
    let sc = Score::score(&colors.color_to_count, None, None, None);
    sc[0]
  } else if let Some(hex) = args.color {
    Argb::from_str(&hex).or(Err(anyhow!(
      "Invalid hexadecimal string '{}' for color argument",
      hex
    )))?
  } else {
    return Err(anyhow!(
      "Neither color nor img was provided: impossible to determine the palette."
    ));
  };

  let mut palette = args.dynamic_palette;
  let theme = ThemeBuilder::with_source(argb)
    .variant(variant.clone())
    .build();
  let key_color: Argb = theme.palettes.primary.key_color().into();

  let scheme = (if args.dark_mode {
    theme.schemes.dark
  } else {
    theme.schemes.light
  })
  .into_iter()
  .collect::<HashMap<_, _, RandomState>>();

  for val in palette.0.values_mut() {
    *val = boost_chroma_tone(
      harmonize(
        *val,
        key_color,
        args.harmony.min(1.0).max(0.0),
        args.harmonize_threshold.min(180.0).max(0.0),
      ),
      Some(1.0),
      Some(1.0 + args.fg_boost.min(1.0).max(0.0) * (if args.dark_mode { 1.0 } else { -1.0 })),
    );
  }

  // Add all material colors in the palette
  for (mk, mv) in scheme.into_iter() {
    palette.0.insert(mk, mv);
  }

  Ok(palette)
}
