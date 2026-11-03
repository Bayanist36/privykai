/* Injects the shared icon sprite and the mock status bar.
   Keeps every screen file free of duplicated SVG noise. */
(function () {
  var sprite =
    '<svg xmlns="http://www.w3.org/2000/svg" style="position:absolute;width:0;height:0;overflow:hidden" aria-hidden="true">' +
    '<symbol id="i-check" viewBox="0 0 24 24"><path d="M20 6 9 17l-5-5"/></symbol>' +
    '<symbol id="i-plus" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></symbol>' +
    '<symbol id="i-flame" viewBox="0 0 24 24"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.07-2.14-.22-4.05 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.15.43-2.29 1-3a2.5 2.5 0 0 0 2.5 2.5Z"/></symbol>' +
    '<symbol id="i-bell" viewBox="0 0 24 24"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></symbol>' +
    '<symbol id="i-today" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M8.2 12.2 10.8 15l5.2-6"/></symbol>' +
    '<symbol id="i-chart" viewBox="0 0 24 24"><path d="M12 20V10M18 20V4M6 20v-4"/></symbol>' +
    '<symbol id="i-settings" viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.6a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z"/></symbol>' +
    '<symbol id="i-back" viewBox="0 0 24 24"><path d="M19 12H5M12 19l-7-7 7-7"/></symbol>' +
    '<symbol id="i-chevron-right" viewBox="0 0 24 24"><path d="M9 18l6-6-6-6"/></symbol>' +
    '<symbol id="i-droplet" viewBox="0 0 24 24"><path d="M12 2.7 17.7 8.4a8 8 0 1 1-11.4 0Z"/></symbol>' +
    '<symbol id="i-dumbbell" viewBox="0 0 24 24"><path d="M6.5 6.5v11M3.5 9v6M17.5 6.5v11M20.5 9v6M6.5 12h11"/></symbol>' +
    '<symbol id="i-book" viewBox="0 0 24 24"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2Z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7Z"/></symbol>' +
    '<symbol id="i-moon" viewBox="0 0 24 24"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79Z"/></symbol>' +
    '<symbol id="i-lotus" viewBox="0 0 24 24"><path d="M12 20c-2.2 0-4-1.4-4-3.2 0-1.9 1.8-3.6 4-4.8 2.2 1.2 4 2.9 4 4.8 0 1.8-1.8 3.2-4 3.2Z"/><path d="M12 20c-4.4 0-8-1.3-8-3 0-1.5 2.3-2.7 5.2-3M12 20c4.4 0 8-1.3 8-3 0-1.5-2.3-2.7-5.2-3"/></symbol>' +
    '<symbol id="i-walk" viewBox="0 0 24 24"><path d="M4 16v-2.38C4 11.5 2.97 10.5 3 8c.03-2.72 1.49-6 4.5-6C9.37 2 10 3.8 10 5.5c0 3.11-2 5.66-2 8.68V16a2 2 0 1 1-4 0Z"/><path d="M20 20v-2.38c0-2.12 1.03-3.12 1-5.62-.03-2.72-1.49-6-4.5-6C14.63 6 14 7.8 14 9.5c0 3.11 2 5.66 2 8.68V20a2 2 0 1 0 4 0Z"/></symbol>' +
    '<symbol id="i-leaf" viewBox="0 0 24 24"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/></symbol>' +
    '<symbol id="i-sparkles" viewBox="0 0 24 24"><path d="m12 3 1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9Z"/><path d="M19 15.5l.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7ZM5 3l.6 1.4L7 5l-1.4.6L5 7l-.6-1.4L3 5l1.4-.6Z"/></symbol>' +
    '<symbol id="i-clock" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></symbol>' +
    '<symbol id="i-trash" viewBox="0 0 24 24"><path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6M10 11v6M14 11v6"/></symbol>' +
    '<symbol id="i-lock" viewBox="0 0 24 24"><rect x="3.5" y="10.5" width="17" height="10.5" rx="2.5"/><path d="M7.5 10.5V7a4.5 4.5 0 0 1 9 0v3.5"/></symbol>' +
    '<symbol id="i-wifi-off" viewBox="0 0 24 24"><path d="M2 2l20 20"/><path d="M16.7 11.1A11 11 0 0 1 19 12.6M5 12.6a11 11 0 0 1 5.2-2.4M10.7 5.1A16 16 0 0 1 22.6 9M1.4 9a16 16 0 0 1 4.7-2.9M8.5 16.1a6 6 0 0 1 7 0M12 20h.01"/></symbol>' +
    '<symbol id="i-shield" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z"/><path d="m9 12 2 2 4-5"/></symbol>' +
    '<symbol id="i-calendar" viewBox="0 0 24 24"><rect x="3" y="4.5" width="18" height="17" rx="2.5"/><path d="M16 2.5v4M8 2.5v4M3 10h18"/></symbol>' +
    '<symbol id="i-edit" viewBox="0 0 24 24"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/></symbol>' +
    '<symbol id="i-x" viewBox="0 0 24 24"><path d="M18 6 6 18M6 6l12 12"/></symbol>' +
    '<symbol id="i-list" viewBox="0 0 24 24"><path d="M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01"/></symbol>' +
    '<symbol id="i-info" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 16v-4M12 8h.01"/></symbol>' +
    "</svg>";

  var holder = document.createElement("div");
  holder.innerHTML = sprite;
  document.body.insertBefore(holder.firstElementChild, document.body.firstChild);

  var time = "9:41";
  var bars =
    '<span class="statusbar__icons">' +
    '<svg width="17" height="12" viewBox="0 0 17 12" fill="currentColor"><rect x="0" y="8" width="3" height="4" rx="0.8"/><rect x="4.5" y="5.8" width="3" height="6.2" rx="0.8"/><rect x="9" y="3.4" width="3" height="8.6" rx="0.8"/><rect x="13.5" y="1" width="3" height="11" rx="0.8"/></svg>' +
    '<svg width="16" height="12" viewBox="0 0 16 12" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"><path d="M1.4 4.3a10 10 0 0 1 13.2 0"/><path d="M3.9 7a6.4 6.4 0 0 1 8.2 0"/><path d="M6.4 9.5a2.7 2.7 0 0 1 3.2 0"/></svg>' +
    '<svg width="25" height="12" viewBox="0 0 25 12" fill="none"><rect x="0.75" y="0.75" width="20" height="10.5" rx="3" stroke="currentColor" stroke-width="1.2" opacity="0.35"/><rect x="2.5" y="2.5" width="16.5" height="7" rx="1.8" fill="currentColor"/><path d="M22.4 4.2v3.6a2 2 0 0 0 0-3.6Z" fill="currentColor" opacity="0.4"/></svg>' +
    "</span>";

  document.querySelectorAll("[data-statusbar]").forEach(function (el) {
    el.innerHTML = '<span class="statusbar__time">' + time + "</span>" + bars;
  });
})();
