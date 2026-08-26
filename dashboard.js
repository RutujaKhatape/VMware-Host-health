fetch('./Data/hosthealth.json')
  .then(response => response.json())
  .then(data => {

    const container = document.getElementById("clusters");

    const clusters = {};

    data.forEach(host => {

    const clusterName = host.Cluster || "Unassigned";

    if (!clusters[clusterName]) {
        clusters[clusterName] = [];
    }

    clusters[clusterName].push(host);
});

    Object.keys(clusters).forEach(clusterName => {

      const hosts = clusters[clusterName];

      const healthy = hosts.filter(
        h => h.HealthStatus === "Healthy"
      ).length;

      const warning = hosts.filter(
        h => h.HealthStatus === "Warning"
      ).length;

      const critical = hosts.filter(
        h => h.HealthStatus === "Critical"
      ).length;

      let html = `
        <div class="cluster-card">
          <h2>${clusterName}</h2>

          <p>
            Total Hosts: ${hosts.length} |
            🟢 Healthy: ${healthy} |
            🟡 Warning: ${warning} |
            🔴 Critical: ${critical}
          </p>

          <table>
            <thead>
              <tr>
                <th>Host Name</th>
                <th>Health</th>
                <th>ESXi Version</th>
                <th>Active Alarms</th>
                <th>Maintenance</th>
              </tr>
            </thead>
            <tbody>
      `;

      hosts.forEach(host => {

        let color = "green";

        if (host.HealthStatus === "Warning") {
          color = "orange";
        }

        if (host.HealthStatus === "Critical") {
          color = "red";
        }

        html += `
          <tr>
            <td>${host.HostName}</td>
            <td style="color:${color};font-weight:bold">
              ${host.HealthStatus}
            </td>
            <td>${host.ESXiVersion}</td>
            <td>${host.ActiveAlarmCount}</td>
            <td>${host.MaintenanceMode}</td>
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
  });
``