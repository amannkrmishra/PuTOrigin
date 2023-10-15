const axios = require('axios');
const fs = require('fs');

// Add this line to increase the heap size to 8GB
const maxHeapSize = 8192; // 8GB in megabytes

const url = 'https://login.mymobiforce.com/coreapi/api/supportengineerhelper/UpdateSkillInUsers';
const headers = {
  'Content-Type': 'application/json',
  'Accept': 'application json',
  'Token': 'fb9329e9-a0d8-4868-8821-0840f7685d28',
  'Userid': 'U00000000493'
};

const phoneNumbers = fs.readFileSync('MobileNo.txt', 'utf-8').split('\n').map(number => number.trim());

const data = {
  "Skill": "Switch_Router_Installation_Maintenance",
  "ContactNumber": phoneNumbers,
  "AccountId": "0"
};

// Run the script with an increased heap size
const child_process = require('child_process');
const nodeCmd = `node --max-old-space-size=${maxHeapSize} ${process.argv[1]}`;
const options = { maxBuffer: 1024 * 10000 }; // Optionally increase maxBuffer for larger outputs
child_process.execSync(nodeCmd, options);

setInterval(() => {
  axios.put(url, data, { headers: headers })
    .then(response => {
      console.log('Response:', response.data);
    })
    .catch(error => {
      console.error('Error:', error);
    });
}, 100); // Adjust the interval (in milliseconds) as per your requirements
