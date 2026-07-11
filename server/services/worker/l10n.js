// Localized push-notification templates for the worker crons (overdue +
// award). Recipients are grouped by their `users.locale` - the app writes it
// since the i18n release; empty/missing means English, so pre-i18n clients
// keep getting exactly the old strings.
//
// Chore / subject / member names are user content and pass through as-is -
// only the scaffolding around them is translated. Keep the tone in step with
// the app's ARBs (app/lib/l10n/app_*.arb) and the hooks' _l10n_helper.js.

const STRINGS = {
  en: {
    someone: () => "Someone",
    someoneLower: () => "someone",
    aChore: () => "A chore",
    overdueBody: p => `${p.chore} is overdue - ${p.subject} is waiting!`,
    awardSingleTitle: () => "🏆 You won an award!",
    awardSingleBody: p => `You've received an award from ${p.subject} - tap to receive it!`,
    awardMultiTitle: p => `🏆 You won ${p.count} awards!`,
    awardMultiBody: p => `You won ${p.count} awards last week - open to see who crowned you!`,
  },
  de: {
    someone: () => "Jemand",
    someoneLower: () => "jemand",
    aChore: () => "Eine Aufgabe",
    overdueBody: p => `${p.chore} ist überfällig - ${p.subject} wartet!`,
    awardSingleTitle: () => "🏆 Du hast eine Auszeichnung gewonnen!",
    awardSingleBody: p => `Du hast eine Auszeichnung von ${p.subject} bekommen - tippe, um sie abzuholen!`,
    awardMultiTitle: p => `🏆 Du hast ${p.count} Auszeichnungen gewonnen!`,
    awardMultiBody: p => `Du hast letzte Woche ${p.count} Auszeichnungen gewonnen - öffne die App und sieh, wer dich gekrönt hat!`,
  },
  fr: {
    someone: () => "Quelqu'un",
    someoneLower: () => "quelqu'un",
    aChore: () => "Une corvée",
    overdueBody: p => `${p.chore} est en retard - ${p.subject} attend !`,
    awardSingleTitle: () => "🏆 Tu as gagné un trophée !",
    awardSingleBody: p => `${p.subject} t'a décerné un trophée - touche pour le recevoir !`,
    awardMultiTitle: p => `🏆 Tu as gagné ${p.count} trophées !`,
    awardMultiBody: p => `Tu as gagné ${p.count} trophées la semaine dernière - ouvre l'appli pour voir qui t'a couronné !`,
  },
  es: {
    someone: () => "Alguien",
    someoneLower: () => "alguien",
    aChore: () => "Una tarea",
    overdueBody: p => `${p.chore} va con retraso - ¡${p.subject} está esperando!`,
    awardSingleTitle: () => "🏆 ¡Has ganado un trofeo!",
    awardSingleBody: p => `Has recibido un trofeo de ${p.subject} - ¡toca para recogerlo!`,
    awardMultiTitle: p => `🏆 ¡Has ganado ${p.count} trofeos!`,
    awardMultiBody: p => `Ganaste ${p.count} trofeos la semana pasada - ¡abre la app y mira quién te coronó!`,
  },
};

/// Bare language code from a users.locale value ("de_AT" -> "de"; falsy -> "en").
function lang(locale) {
  return String(locale || "en").split(/[-_]/)[0];
}

/// Renders template [key] in [locale], falling back to English for unknown
/// languages or keys.
function t(locale, key, params) {
  const table = STRINGS[lang(locale)] || STRINGS.en;
  const tpl = table[key] || STRINGS.en[key];
  return tpl(params || {});
}

module.exports = { t, lang };
