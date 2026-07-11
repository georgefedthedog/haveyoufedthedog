// Localized push templates for the completion notify hook. Lives in a
// non-`.pb.js` file so PocketBase doesn't auto-load it as a hook; it's
// require()d inside handlers (each runs in its own Goja runtime).
//
// Recipients are grouped by their `users.locale`; empty/missing means
// English, so pre-i18n clients keep getting exactly the old strings.
// Chore / member names are user content and pass through untranslated.
// Keep the tone in step with the worker's l10n.js and the app ARBs.

const STRINGS = {
  en: {
    someone: () => "Someone",
    doneBody: p => `${p.chore} done by ${p.who}`,
    doneFallback: p => `${p.who} logged a completion`,
    undoneBody: p => `${p.chore} undone by ${p.who}`,
    undoneFallback: p => `${p.who} removed a completion`,
  },
  de: {
    someone: () => "Jemand",
    doneBody: p => `${p.chore} erledigt von ${p.who}`,
    doneFallback: p => `${p.who} hat etwas eingetragen`,
    undoneBody: p => `${p.chore} zurückgenommen von ${p.who}`,
    undoneFallback: p => `${p.who} hat einen Eintrag entfernt`,
  },
  fr: {
    someone: () => "Quelqu'un",
    doneBody: p => `${p.chore} faite par ${p.who}`,
    doneFallback: p => `${p.who} a validé une corvée`,
    undoneBody: p => `${p.chore} retirée par ${p.who}`,
    undoneFallback: p => `${p.who} a retiré une corvée`,
  },
  es: {
    someone: () => "Alguien",
    doneBody: p => `${p.chore} hecha por ${p.who}`,
    doneFallback: p => `${p.who} registró una tarea`,
    undoneBody: p => `${p.chore} quitada por ${p.who}`,
    undoneFallback: p => `${p.who} quitó una tarea`,
  },
};

function lang(locale) {
  return String(locale || "en").split(/[-_]/)[0];
}

function t(locale, key, params) {
  const table = STRINGS[lang(locale)] || STRINGS.en;
  const tpl = table[key] || STRINGS.en[key];
  return tpl(params || {});
}

module.exports = { t, lang };
