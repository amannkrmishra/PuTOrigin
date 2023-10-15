const fetch = require('node-fetch');
const fs = require('fs').promises;

const url = 'https://login.mymobiforce.com/coreapi/api/supportengineerhelper/UpdateSkillInUsers';
const headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Token': 'e2d28123-9b63-4e0a-b4c8-038afd0bfa33',
  'Userid': 'U00000000493'
};

async function processPhoneNumber(phoneNumber) {
  const data = {
    "Skill": "Switch_Router_Installation_Maintenance",
    "ContactNumber": phoneNumber,
    "AccountId": "0"
  };

  try {
    const response = await fetch(url, {
      method: 'PUT',
      headers: headers,
      body: JSON.stringify(data)
    });
    const result = await response.json();
    console.log('Response:', result);
  } catch (error) {
    console.error('Error:', error);
  }
}

async function main() {
  try {
    const phoneNumbers = (await fs.readFile('MobileNo.txt', 'utf-8')).split('\n').map(number => number.trim());
    
    for (const phoneNumber of phoneNumbers) {
      await processPhoneNumber(phoneNumber);
      // Introduce a delay of 3 milliseconds before processing the next phone number
      await new Promise(resolve => setTimeout(resolve, 3));
    }

    console.log('All phone numbers processed.');
  } catch (error) {
    console.error('Error:', error);
  }
}

main();
