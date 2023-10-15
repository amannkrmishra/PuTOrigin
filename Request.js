const fs = require('fs');
const axios = require('axios');
const XLSX = require('xlsx');

//const endpoint = 'https://login.mymobiforce.com/FreelancerAPI/api/FreelancerUser/GetActiveUsersByFiltersWithDynaPage';
const endpoint = 'https://login.mymobiforce.com/FreelancerAPI/api/FreeLancerRegistration/FreelancerListingByPaging?reqUserid=U00000000471';

const headers = {
  'Content-Type': 'application/json',
  'Token': 'f05aea80-1556-45bb-8a70-d46c7f47c8c8',
  'UserId': 'U00000000471',
};

// Define the number of pages to fetch (adjust as needed)
const totalPagesToFetch = 50; // For example, fetch data from pages 1 to 50

// Function to fetch data for a given page
const fetchDataForPage = async (pageIndex) => {
  const payload = {
    "PageIndex": pageIndex,
    "PageSize": 300, // Adjust as needed
    "ActivationStartDate": "2017-01-01",
    "ActivationEnddate": "2023-10-11",
    "State": "",
    "Cities": "",
    "Pincodes": [],
    "Skill": "",
    "ExperienceStart": "",
    "Certificates": "",
    "IsBikeAvailable": false,
    "IsMobileAvailable": false,
    "IsLaptopAvailable": false,
    "Tools": "",
    "JobCountStart": "",
    "RatingStart": 0,
    "RatingEnd": null,
    "PreferredTalentPool": false,
    "IsStudent": false,
    "IsOpenForInternship": false,
    "IsAdharVerified": false,
    "IsAuthorizedServicePartner": false,
    "IsPanVerified": false,
    "FreelancerRole": "",
    "UserName": "",
    "UserId": "",
    "OrderBy": "CreatedOn",
    "SortType": "desc"
  };

  try {
    const response = await axios.put(endpoint, payload, { headers });
    return response.data.Users || [];
  } catch (error) {
    console.error('Error fetching data for page', pageIndex, ':', error);
    return [];
  }
};

(async () => {
  const selectedFieldsArray = [];

  // Loop through pages and fetch data
  for (let pageIndex = 1; pageIndex <= totalPagesToFetch; pageIndex++) {
    console.log('Fetching data for page', pageIndex);
    const userData = await fetchDataForPage(pageIndex);

    // Print the data grabbed for the current page
    console.log('Data grabbed for page', pageIndex, ':', userData);

    selectedFieldsArray.push(
      ...userData.map(user => ({
        UserId: user.UserId,
        Password: user.Password,
        OTP: user.OTP,
        Name: user.Name,
        DOB: user.DOB,
        UserStatus: user.UserStatus,
        PersonalEmail: user.PersonalEmail,
        ContactNumber: user.ContactNumber,
        AlternativeContactNumber: user.AlternativeContactNumber,
        Role: user.Role,
        ReportingTo: user.ReportingTo,
        ActivationDateObj: user.ActivationDateObj,
        UniqueKey: user.UniqueKey,
        PermanentAdd1: user.PermanentAdd1,
        PermanentAdd2: user.PermanentAdd2,
        PermanentCity: user.PermanentCity,
        PermanentPinCode: user.PermanentPinCode,
        CurrentCity: user.CurrentCity,
        JobCompleted: user.JobCompleted,
        RegistrationNo: user.RegistrationNo,
        City: user.City,
        Pincode: user.Pincode,
        CurrentLatitude: user.CurrentLatitude,
        CurrentLongitude: user.CurrentLongitude,
        MMFPrimeMember: user.MMFPrimeMember,
        IsBankVerified: user.IsBankVerified,
        IsUPIVerified: user.IsUPIVerified,
      }))
    );
  }

  if (selectedFieldsArray.length > 0) {
    // Save data to Excel file
    const wb = XLSX.utils.book_new();
    const ws = XLSX.utils.json_to_sheet(selectedFieldsArray);
    XLSX.utils.book_append_sheet(wb, ws, 'Users');
    XLSX.writeFile(wb, 'Users.xlsx');
    console.log('Data saved to Users.xlsx');
  } else {
    console.log('No user data found in the response.');
  }
})();
