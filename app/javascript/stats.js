/* eslint no-console:0 */

window.initializeChart = async function(rawData, containerId) {
  let container = document.getElementById(containerId);
  let canvas = document.createElement("canvas")
  canvas.id = containerId + "-canvas";
  canvas.width = parseInt(getComputedStyle(container).width.replace("px", ""), 10) - 5;
  canvas.height = 400;
  container.appendChild(canvas)


  console.log(getComputedStyle(canvas).getPropertyValue("--chart-fill-color"))
  let data = {
    labels: Object.keys(rawData),
    datasets: [{
      backgroundColor: getComputedStyle(canvas).getPropertyValue("--chart-background-color"),
      borderColor: getComputedStyle(canvas).getPropertyValue("--chart-border-color"),
      data: Object.values(rawData)
    }]
  }

  let ctx = canvas.getContext("2d");
  const { Chart, CategoryScale, LinearScale, BarController, BarElement, Tooltip } = await import('chart.js')
  Chart.register([CategoryScale, LinearScale, BarController, BarElement, Tooltip])
  new Chart(ctx, {
    type: 'bar',
    data: data,
    options: {
      scaleStartValue: 0,
      legend: {display: false},
      scales: {
        x: {
          grid: {display: false}
        },
        y: {
          suggestedMax: 10,
          beginAtZero: true
        }
      },
      plugins: {
        tooltip: {
          enabled: true
        }
      }
    }
  });
}
