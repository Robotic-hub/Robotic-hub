
function printDocument(pdfUrl) {
    const printWindow = window.open(pdfUrl, "_blank");
    printWindow.onload = function () {
      printWindow.print();
    };
  }