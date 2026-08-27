fetch('./Data/hosthealth.json')
  .then(response => response.json())
  .then(data => {

    const container = document.getElementById("clusters");
    const summary = document.getElementById("summary");

    container.innerHTML = "";
    summary.innerHTML = "";

    let totalHosts = data.length;

    let healthyHosts =
      data.filter(h => h.HealthStatus === "Healthy").length;

    let warningHosts =
      data.filter(h => h.HealthStatus === "Warning").length;

    let criticalHosts =
      data.filter(h => h.HealthStatus === "Critical").length;

    summary.innerHTML = `
      <div class="summary">
        <strong>Total Hosts:</strong> ${totalHosts}
        &nbsp;&nbsp;|&nbsp;&nbsp;
        🟢 <strong>Healthy:</strong> ${healthyHosts}
        &nbsp;&nbsp;|&nbsp;&nbsp;
        🟡 <strong>Warning:</strong> ${warningHosts}
        &nbsp;&nbsp;|&nbsp;&nbsp;
        🔴 <strong>Critical:</strong> ${criticalHosts}
      </div>
      <br>
    `;

    const clusters = {};

    data.forEach(host => {

      const clusterName = host.Cluster || "Unassigned";

      if (!clusters[clusterName]) {
        clusters[clusterName] = [];
      }

      clusters[clusterName].push(host);
    });

    Object.keys(clusters)
      .sort()
      .forEach(clusterName => {

      const hosts = clusters[clusterName];

      const healthy =
        hosts.filter(h => h.HealthStatus === "Healthy").length;

      const warning =
        hosts.filter(h => h.HealthStatus === "Warning").length;

      const critical =
        hosts.filter(h => h.HealthStatus === "Critical").length;

      let html = `
      <div class="cluster-card">

        <h2>${clusterName}</h2>

        <div class="summary">
          Total Hosts: ${hosts.length}
          |
          🟢 ${healthy}
          |
          🟡 ${warning}
          |
          🔴 ${critical}
        </div>

        <table>
          <thead>
            <tr>
              <th>Host Name</th>
              <th>Health</th>
              <th>CPU %</th>
              <th>Memory %</th>
              <th>Alert Definition</th>
              <th>Version</th>
              <th>Config Issues</th>
            </tr>
          </thead>
          <tbody>
      `;

      hosts.forEach(host => {

        let healthColor = "green";

        if (host.HealthStatus === "Warning") {
          healthColor = "orange";
        }

        if (host.HealthStatus === "Critical") {
          healthColor = "red";
        }

        let memoryColor = "green";

        if (host.MemoryUsagePercent >= 90) {
          memoryColor = "red";
        }
        else if (host.MemoryUsagePercent >= 80) {
          memoryColor = "orange";
        }

        html += `
          <tr>
            <td>${host.HostName}</td>

            <td style="
                color:${healthColor};
                font-weight:bold;">
                ${host.HealthStatus}
            </td>

            <td>
                ${Number(host.CPUUsagePercent).toFixed(2)}%
            </td>

            <td style="
                color:${memoryColor};
                font-weight:bold;">
                ${Number(host.MemoryUsagePercent).toFixed(2)}%
            </td>

            <td>
                ${host.AlertDefinitions || "Healthy"}
            </td>

            <td>
                ${host.ESXiVersion}
            </td>

            <td>
                ${host.ConfigIssues}
            </td>
          </tr>
        `;
      });

      html += `
          </tbody>
        </table>
      </div>
      `;

      container.innerHTML += html;
    });

  })
  .catch(error => {
    console.error("Error loading hosthealth.json:", error);
  });