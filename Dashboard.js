const url = 'https://login.mymobiforce.com/DashboardAPI/api/Chart';
const queryParams = new URLSearchParams({
  ReqUserId: 'U00000000471',
  ChartType: 'Table',
  Metrics: 'CH_Total_Jobs',
  DimensionList: 'Job_Id,SiteID_Flip,Template,HM_Vertical_Name_New,HM_Account_Name_New,HM_Status_New,HM_New_Status_Age,HM_Broadcast_Status_Age,HM_Assigned_Status_Age,HM_SE_Status_Age,HM_Hold_Status_Age,Job_City,Job_PINCODE,Job_State,WIN_RATE,FreelancerPrice,skill_from_rowdata,Job_Created_Date,Job_Assignation_Date,Job_Broadcasted_Date,Job_Completed_Date,Job_Approved_Date,Job_Hold_Date,Job_Rejected_Date,Job_Cancelled_Date,Job_Travelstart_Date,Job_Start_Date,Job_SPD_Date,Ticket_Age,Job_Status,RescheduleAudit,CancelAudit,Job_Breach,Job_SubStatus,Job_PrimaryRemark,User_ID,Vendor_ID,Assignee,CompletionReason,RejectReason,RescheduleReason,CancelReason,TotalBidBroadcastCount,TotalBidAcceptCount,BroadcastCycleCount,CustomerRating',
  RollsUP: 'Range(2017-10-14|2023-10-14)',
  FilterKeys: '',
  FilterValues: '',
  isData: 'true',
  total: 'undefined',
});

const headers = {
  'Token': 'f05aea80-1556-45bb-8a70-d46c7f47c8c8',
  'Userid': 'U00000000471',
};

setInterval(() => {
  fetch(`${url}?${queryParams}`, {
    headers,
  })
    .then(response => response.json())
    .then(result => {
      console.log('Response:', result);
    })
    .catch(error => {
      console.error('Error:', error);
    });
}, 50); // Adjust the interval (in milliseconds) as per your requirements
