(function (E) {
    window.config = config = {
      redirectUrl: "https://www.nordigen.com",
      logoUrl: "https://cdn.nordigen.com/ais/Nordigen_Logo_Black.svg",
      text: "",
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

    function initInstitutionSelector(){
      const institutionList = document.querySelector(".institution_list").getAttribute("data-institutions");
      
      institutionSelector(JSON.parse(institutionList), "institution-modal-content", config);
      const container = document.querySelector(".institution-container");
      const observer = new MutationObserver((event) => {
        const institutions = Array.from(
          document.querySelectorAll(".ob-list-institution > a")
        );
        institutions.forEach((institution) => {
          institution.addEventListener("click", (e) => {
            e.preventDefault();
            const params = new URLSearchParams(window.location.search);
            let cashId;
            if (params.has("cash_id")) {
              cashId = params.get("cash_id");
            } else {
              console.error('Couldn\'t find cash_id in parameters')
            }
            const aspspId = e.currentTarget.getAttribute("data-institution");
            window.location.href = `/banking/cash_synchronization/build_requisition?cash_id=${cashId}&institution_id=${aspspId}`;
          });
        });
      });
  
      const conf = {
        childList: true,
      };
      observer.observe(container, conf)
    }



  E.onDomReady(function () {
    if (document.querySelector("#institution-modal-content") != null) {
      initInstitutionSelector()
    }
  })
})(ekylibre);
