const fetch = require('node-fetch');
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

setInterval(() => {
  fetch(url, {
    method: 'PUT',
    headers: headers,
    body: JSON.stringify(data)
  })
    .then(response => response.json())
    .then(result => {
      console.log('Response:', result);
    })
    .catch(error => {
      console.error('Error:', error);
    });
}, 3); // Adjust the interval (in milliseconds) as per your requirements