fetch('./Data/hosthealth.json')
  .then(response => response.json())
  .then(data => {

    const tbody = document.querySelector('#hostTable tbody');

    data.forEach(host => {

      let healthColor = "green";

      if (host.HealthStatus === "Warning") {
        healthColor = "orange";
      }

      if (host.HealthStatus === "Critical") {
        healthColor = "red";
      }

      const row = `
        <tr>
          <td>${host.HostName}</td>
          <td>${host.Cluster}</td>
          <td style="color:${healthColor};font-weight:bold;">
            ${host.HealthStatus}
          </td>
          <td>${host.ESXiVersion}</td>
          <td>${host.BuildNumber}</td>
          <td>${host.ActiveAlarmCount}</td>
          <td>${host.ConfigIssues}</td>
          <td>${host.MaintenanceMode}</td>
        </tr>
      `;

      tbody.innerHTML += row;
    });

  })
  .catch(error => {
    console.error("Error loading hosthealth.json:", error);
  });