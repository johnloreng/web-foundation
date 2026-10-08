// ---------- 1. Elements and settings ----------
const textArea = document.querySelector("#note-text");
const charCount = document.querySelector("#char-count");
const wordCount = document.querySelector("#word-count");
const clearBtn = document.querySelector("#clear-btn");
const themeBtn = document.querySelector("#theme-toggle");
 
const MAX = 200;
const WARN_AT = 180;
const DRAFT_KEY = "note-draft";
const THEME_KEY = "theme";
 
// ---------- 2. Counting ----------
function countWords(text) {
  const trimmed = text.trim();
  if (trimmed === "") return 0;
  return trimmed.split(/\s+/).length; // split on any run of spaces
}
 
function updateCounts() {
  const text = textArea.value;
  const chars = text.length;
  const words = countWords(text);
 
  charCount.textContent = `${chars} / ${MAX} characters`;
  wordCount.textContent = words === 1 ? "1 word" : `${words} words`;
 
  // remove both classes, then add the one that applies (if any)
  charCount.classList.remove("warning", "over");
  if (chars > MAX) {
    charCount.classList.add("over");
  } else if (chars > WARN_AT) {
    charCount.classList.add("warning");
  }
}
 
// ---------- 3. Draft saving ----------
function saveDraft() {
  localStorage.setItem(DRAFT_KEY, textArea.value);
}
 
function clearAll() {
  textArea.value = "";
  localStorage.removeItem(DRAFT_KEY);
  updateCounts();
  textArea.focus();
}
 
// ---------- 4. Theme ----------
function applyTheme(theme) {
  const isDark = theme === "dark";
  document.body.classList.toggle("dark", isDark); // add if true, remove if false
  themeBtn.textContent = isDark ? "Light mode" : "Dark mode";
}
 
function toggleTheme() {
  const newTheme = document.body.classList.contains("dark") ? "light" : "dark";
  applyTheme(newTheme);
  localStorage.setItem(THEME_KEY, newTheme);
}
 
// ---------- 5. Events ----------
textArea.addEventListener("input", () => {
  updateCounts();
  saveDraft();
});
 
textArea.addEventListener("keydown", (event) => {
  if (event.key === "Escape") clearAll();
});
 
clearBtn.addEventListener("click", clearAll);
themeBtn.addEventListener("click", toggleTheme);
 
// ---------- 6. Restore saved state on page load ----------
textArea.value = localStorage.getItem(DRAFT_KEY) || "";
applyTheme(localStorage.getItem(THEME_KEY) || "light");
updateCounts();