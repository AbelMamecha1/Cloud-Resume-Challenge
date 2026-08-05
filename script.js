const counterElement = document.getElementById("visitor-count");
const functionUrl = "https://amamecharesumefunc2026.azurewebsites.net/api/GetVisitorCount";

fetch(functionUrl)
  .then(response => response.json())
  .then(data => {
    counterElement.textContent = data.count;
  })
  .catch(error => {
    console.error("Error fetching visitor count:", error);
    counterElement.textContent = "unavailable";
  });