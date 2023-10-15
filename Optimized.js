const superagent = require('superagent');
const superagentRetry = require('superagent-retry'); // Import superagent-retry
const fs = require('fs');

const url = 'https://login.mymobiforce.com/coreapi/api/supportengineerhelper/UpdateSkillInUsers';
const headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Token': 'e2d28123-9b63-4e0a-b4c8-038afd0bfa33',
  'Userid': 'U00000000493'
};

const phoneNumbers = fs.readFileSync('MobileNo.txt', 'utf-8').split('\n').map(number => number.trim());

const data = {
  "Skill": "Switch_Router_Installation_Maintenance",
  "ContactNumber": phoneNumbers,
  "AccountId": "0"
};

// Use superagentRetry to add retry functionality
const agent = superagentRetry(superagent, {
  retries: 3, // Number of retries
  factor: 2, // Exponential backoff factor
});

setInterval(() => {
  agent
    .put(url)
    .set(headers)
    .send(data)
    .then(response => {
      console.log('Response:', response.body);
    })
    .catch(error => {
      console.error('Error:', error);
    });
}, 100); // Adjust the interval (in milliseconds) as per your requirements
