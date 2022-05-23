(function (E) {
  E.onDomReady(function () {
    window.config = config = {
      redirectUrl: "https://www.nordigen.com",
      logoUrl: "https://cdn.nordigen.com/ais/Nordigen_Logo_Black.svg",
      text: "Maquette de dev connection bancaire",
      countryFilter: true,
      styles: {
        // Primary
        fontFamily:
          "https://fonts.googleapis.com/css2?family=Roboto&display=swap",
        fontSize: "15",
        backgroundColor: "#F2F2F2",
        textColor: "#222",
        // Modal
        modalTextColor: "#1B2021",
        modalBackgroundColor: "#fff",
        hoverColor: "#F1F1F1",
        // Button
        buttonColor: "#3A53EE",
        buttonTextColor: "#fff",
      },
    };

    const data = document
      .querySelector(".institution_list")
      .getAttribute("data-institutions");

    institutionSelector(JSON.parse(data), "institution-modal-content", config);

    const container = document.querySelector(".institution-container");
    const observer = new MutationObserver((event) => {
      const institutions = Array.from(
        document.querySelectorAll(".ob-list-institution > a")
      );
      console.log(institutions);
      institutions.forEach((institution) => {
        institution.addEventListener("click", (e) => {
          e.preventDefault();
          const aspspId = e.currentTarget.getAttribute("data-institution");
          window.location.href = `/banking/transactions/${aspspId}/build_requisition`;
        });
      });
    });

    const conf = {
      childList: true,
    };
    observer.observe(container, conf);
  });
})(ekylibre);
