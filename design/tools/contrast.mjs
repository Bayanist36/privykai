/*
 * WCAG contrast audit for the design tokens.
 * Usage: node tools/contrast.mjs
 */
const hex = (value) => {
  const clean = value.replace("#", "");
  return [
    parseInt(clean.slice(0, 2), 16),
    parseInt(clean.slice(2, 4), 16),
    parseInt(clean.slice(4, 6), 16),
  ];
};

const blend = (fg, alpha, bg) =>
  fg.map((channel, i) => Math.round(channel * alpha + bg[i] * (1 - alpha)));

const linear = (channel) => {
  const s = channel / 255;
  return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
};

const luminance = (rgb) =>
  0.2126 * linear(rgb[0]) + 0.7152 * linear(rgb[1]) + 0.0722 * linear(rgb[2]);

const ratio = (a, b) => {
  const l1 = luminance(a);
  const l2 = luminance(b);
  return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
};

const c = {
  white: "#FFFFFF",
  sand25: "#FAF8F3",
  sand50: "#F4F1E9",
  sand100: "#EAE5DA",
  sand200: "#DCD5C6",
  sand300: "#C4BCAA",
  ink900: "#18201B",
  ink700: "#3C463F",
  ink500: "#6B756D",
  ink300: "#A9B0AA",
  green700: "#1F5C43",
  green600: "#2A7052",
  green500: "#3B8A68",
  green200: "#BFD9CB",
  green100: "#DCEBE1",
  green50: "#EDF4EF",
  amber800: "#8A4F13",
  amber600: "#B87120",
  amber500: "#D98A2B",
  amber100: "#F8E9D2",
  red600: "#B23B32",
  red50: "#FBECEA",
  darkBg: "#101512",
  darkSurface: "#1A211C",
  darkSubtle: "#212A23",
  darkBorder: "#2C362E",
  darkBorderStrong: "#3C4A40",
  darkText: "#EDF2EE",
  darkText2: "#A9B3AC",
  darkText3: "#7A857D",
  darkAccent: "#58A985",
  darkAccentPressed: "#6DBB97",
  darkAccentSoft: "#1E2F26",
  darkGreen700: "#8CC6A8",
  darkAmber500: "#E0A354",
  darkAmber100: "#3A2A16",
  darkDanger: "#E07A70",
  darkDangerSoft: "#3A211E",
  darkOnAccent: "#0D1A13",
  darkSnackAction: "#8CC6A8",
  darkOverlay: "#E8EFE9",
  darkOnOverlay: "#18201B",
  habitGreenBase: "#2A7052",
  habitGreenSoft: "#E4EFE8",
  habitBlueBase: "#3C6E9F",
  habitBlueSoft: "#E6EEF6",
  habitAmberBase: "#B87120",
  habitAmberSoft: "#F8E9D2",
  habitCoralBase: "#B45A4A",
  habitCoralSoft: "#F7E4DF",
  habitVioletBase: "#6B5B95",
  habitVioletSoft: "#ECE8F4",
  habitTealBase: "#2F7C77",
  habitTealSoft: "#E1F0EE",
};

const rows = [];
const pair = (label, fg, bg, note = "") => {
  rows.push({ label, fg, bg, ratio: ratio(hex(fg), hex(bg)), note });
};
const alpha = (label, fg, a, bg, note = "") => {
  const bgRgb = hex(bg);
  const composite = blend(hex(fg), a, bgRgb);
  rows.push({
    label,
    fg: fg + " @ " + Math.round(a * 100) + "%",
    bg,
    ratio: ratio(composite, bgRgb),
    note,
  });
};

// Light surfaces and text
pair("text-primary on bg-app", c.ink900, c.sand25, "AAA");
pair("text-secondary on bg-app", c.ink500, c.sand25, "AA 4.5");
pair("text-tertiary on bg-app", c.ink300, c.sand25, "placeholder only");
pair("text-secondary on surface", c.ink500, c.white, "AA");
pair("text-tertiary on surface", c.ink300, c.white, "placeholder only");
pair("green700 on accent-soft", c.green700, c.green50, "AAA");
pair("danger on danger-soft", c.red600, c.red50, "AA");
pair("amber600 on amber100", c.amber600, c.amber100, "AA");
pair("border-strong vs surface", c.sand200, c.white, "non-text 3:1");
pair("border-subtle vs surface", c.sand100, c.white, "divider only");

// Hero cards (light)
pair("white on green600", c.white, c.green600, "AA");
alpha("white 88% on green600", c.white, 0.88, c.green600, "spec value");
alpha("white 90% on green600", c.white, 0.9, c.green600, "spec percent");
alpha("white 72% on green600", c.white, 0.72, c.green600, "current progress label");

// Buttons and states
pair("on-accent on accent", c.white, c.green600, "AA");
pair("text-tertiary on disabled bg", c.ink300, c.sand200, "disabled text");
pair("text-tertiary on sand100", c.ink300, c.sand100, "disabled spec");

// Habit colours
const habits = [
  ["green", c.habitGreenBase, c.habitGreenSoft],
  ["blue", c.habitBlueBase, c.habitBlueSoft],
  ["amber", c.habitAmberBase, c.habitAmberSoft],
  ["coral", c.habitCoralBase, c.habitCoralSoft],
  ["violet", c.habitVioletBase, c.habitVioletSoft],
  ["teal", c.habitTealBase, c.habitTealSoft],
];
for (const [name, base, soft] of habits) {
  pair("white check on habit." + name + ".base", c.white, base, "non-text 3:1");
  pair("habit." + name + ".base on soft", base, soft, "indicator on tile");
}

// Dark theme
pair("dark text-primary on bg", c.darkText, c.darkBg, "AA");
pair("dark text-secondary on bg", c.darkText2, c.darkBg, "AA");
pair("dark text-tertiary on bg", c.darkText3, c.darkBg, "zero streak");
pair("dark text-tertiary on surface", c.darkText3, c.darkSurface, "zero streak");
pair("dark text-secondary on surface", c.darkText2, c.darkSurface, "AA");
pair("dark accent on bg", c.darkAccent, c.darkBg, "large text / icon");
pair("dark green700 on accent-soft", c.darkGreen700, c.darkAccentSoft, "AA");
pair("dark danger on danger-soft", c.darkDanger, c.darkDangerSoft, "AA");
pair("dark badge on amber-soft", c.darkAmber500, c.darkAmber100, "AA");
pair("dark border vs bg", c.darkBorder, c.darkBg, "card boundary 3:1");
pair("dark border vs surface", c.darkBorder, c.darkSurface, "card boundary 3:1");
pair("dark border-strong vs surface", c.darkBorderStrong, c.darkSurface, "proposed");
pair("dark on-accent on accent", c.darkOnAccent, c.darkAccent, "AA");
pair("dark on-accent on accent-pressed", c.darkOnAccent, c.darkAccentPressed, "AA");
alpha("dark on-accent 88% on accent", c.darkOnAccent, 0.88, c.darkAccent, "labels");
alpha("dark on-accent 72% on accent", c.darkOnAccent, 0.72, c.darkAccent, "current label");
pair("dark snack action on overlay", c.darkSnackAction, c.darkOverlay, "snackbar action");
pair("dark on-overlay on overlay", c.darkOnOverlay, c.darkOverlay, "snackbar text");

const fmt = (n) => n.toFixed(2).replace(".", ",");
for (const row of rows) {
  console.log(
    [
      row.label.padEnd(46),
      String(row.fg).padEnd(24),
      String(row.bg).padEnd(10),
      fmt(row.ratio).padStart(6),
      row.note,
    ].join(" | "),
  );
}
