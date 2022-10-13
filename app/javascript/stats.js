/* eslint no-console:0 */

window.initializeChart = async function(rawData, containerId) {
  let data = {
    labels: Object.keys(rawData),
    datasets: [{
      fillColor : "rgba(220,220,220,0.5)",
      strokeColor : "rgba(220,220,220,1)",
      data: Object.values(rawData)
    }]
  }

  let container = document.getElementById(containerId);
  let canvas = document.createElement("canvas")
  canvas.id = containerId + "-canvas";
  canvas.width = parseInt(getComputedStyle(container).width.replace("px", ""), 10) - 5;
  canvas.height = 400;
  container.appendChild(canvas)

  let ctx = canvas.getContext("2d");
  await import('chart.js')
  new Chart(ctx, {
    type: 'bar',
    data: data,
    options: {
      scaleStartValue: 0,
      legend: {display: false},
      scales: {
        xAxes: [{
          gridLines: {display: false}
        }],
        yAxes: [{
          ticks: {
            suggestedMax: 10,
            beginAtZero: true,
          }
        }]
      }
    }
  });
}
