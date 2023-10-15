const XLSX = require('xlsx');
const fetch = require('node-fetch');

// Load the Excel file
const workbook = XLSX.readFile('Power.xlsx');

// Assuming the data is in the first sheet (index 0)
const sheetName = workbook.SheetNames[0];
const sheet = workbook.Sheets[sheetName];

// Convert the sheet data into an array of objects
const data = XLSX.utils.sheet_to_json(sheet);

// Loop through each row in the Excel sheet
data.forEach((excelData) => {
  // Your API request code for each row
  const baseUrl = 'https://login.mymobiforce.com/coreapi/api/Ticket/UpdateJobPaymentDynamicPrice';

  // Construct the dynamic URL with data from Excel
  const dynamicUrl = `${baseUrl}?reqUserId=U00000000471&TicketId=${excelData['Ticket ID']}&BroadcastRate=${excelData['dLineItemWinPrice']}&MobiforceCommission=0&FreelancerRate=${excelData['dLineItemFreelancerPrice']}&IsFinalApproval=true`;

  const headers = {
    'Token': 'f37f81c4-2e72-426b-b54d-03db3db0f34c',
    'Userid': 'U00000000493',
    'Content-Type': 'application/json', // Set the correct Content-Type header
  };

  // Use the data from Excel in your payload
  const payload = {
    TicketId: excelData['Ticket ID'],
    IsCollectionFlag: true,
    CollectionPercentage: 0,
    CollectionAmount: 0,
    LineItemRequestList: [
    {
      LineItemDescription: 'Others',
      LineItemCategory: 'Service',
      dLineItemWinPrice: excelData['dLineItemWinPrice'], // Updated value
      LineItemQuantity: 1, // Updated value
      FreelancerPrice: null,
      LineItemRemark: 'Done',
      AddedFromField: null,
      LineItemCompanyProvided: 'No',
      LineItemId: 'LI302000004', // Updated value if necessary
      LineItemCode: 'tr44', // Updated value if necessary
      LineItemUnit: 'INR',
      UserId: null,
      LineItemType: 'MasterInventory',
      IsStockItem: false,
      LineItemAttachment: '',
      LineItemApprovalRemark: null,
      IsCustomerApprovalNeeded: false,
      CustomerApprovalStatus: null,
      BackendApprovalStatus: 'pending',
      IsBackendApprovalNeeded: false,
      LineItemHSNCode: null,
      LineItemDisplayDescription: null,
      dLineItemFreelancerPrice: excelData['dLineItemFreelancerPrice'], // Updated value
      ZOHOWarehouseName: null,
      ZOHOSalesOrderId: null,
      ZOHOSalesOrderStatus: null,
      LineItemAction: null,
      edit: false,
    },
  ],
};

  // Send a PUT request for each row
  fetch(dynamicUrl, {
    method: 'PUT',
    headers: headers,
    body: JSON.stringify(payload),
  })
    .then((response) => response.json())
    .then((apiResponse) => {
      console.log('API Response for Ticket ID:', excelData['Ticket ID'], apiResponse);
    })
    .catch((error) => {
      console.error('API Error for Ticket ID:', excelData['Ticket ID'], error);
    });
});
