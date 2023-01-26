function toggleDetails() {
  if (document.getElementById("toggle").innerHTML == "Collapse All") {
    document.getElementById("toggle").innerHTML = "Expand All";
    document.body.querySelectorAll(".topic, .entry").forEach((e) => e.removeAttribute('open'));
  } else {
    document.getElementById("toggle").innerHTML = "Collapse All";
    document.body.querySelectorAll(".topic").forEach((e) => e.setAttribute('open', true));
    document.body.querySelectorAll(".entry").forEach((e) => e.removeAttribute('open'));
  }
}