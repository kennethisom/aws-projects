import * as https from 'node:https';
import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";
const ses = new SESClient({ region: "us-east-2" });

let uri = 'https://api.openweathermap.org/data/3.0/onecall?lat=29.4208472&lon=-98.7371047&appid=2d7db63c26d76b1841277b2f7b03ee5e&units=imperial';

const ALERT_THRESHOLD = 60; // Fahrenheit

async function makeRequest(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (response) => {
      let data = '';

      response.setEncoding('utf8');

      // Collect data chunks
      response.on('data', (chunk) => {
        data += chunk;
      });

      // Resolve the promise when the response ends
      response.on('end', () => {
        resolve(data);
      });

      // Handle errors
      response.on('error', (err) => {
        reject(err);
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

export const handler = async (event) => {
    let response = await makeRequest(uri);
    response = JSON.parse(response);

    let alert = false;
    let alertMessage = null;
    let previousHourDate = null;
    let lastHourAboveThresholdDate = null;

    let high = Number(response.daily[0].temp.max).toFixed();
    let low = Number(response.daily[0].temp.min).toFixed();
    let hourLow = null;

    let nextDay = false;
    for (let hour of response.hourly) {
        let forecastDate = new Date(hour.dt * 1000);
        let forecastHour = forecastDate.toLocaleString('en-US', { timeZone: 'America/Chicago',hour: 'numeric' });;

        if (forecastHour === '12 AM') nextDay = true;
        else if (nextDay && forecastHour === '10 AM') break;

        if (!hourLow || hour.temp < hourLow) hourLow = hour.temp;
        if (!lastHourAboveThresholdDate && hour.temp < ALERT_THRESHOLD) {
            lastHourAboveThresholdDate = previousHourDate;
        }

        previousHourDate = forecastDate;
    }
    if (hourLow < low) low = Number(hourLow).toFixed();

    if (high >= ALERT_THRESHOLD && low < ALERT_THRESHOLD) {
        alert = true;
        let alertTime = lastHourAboveThresholdDate ? `after ${lastHourAboveThresholdDate.toLocaleString('en-US', { timeZone: 'America/Chicago' })}` : 'now';
        alertMessage = `Low of ${low} tonight. Below ${ALERT_THRESHOLD} ${alertTime}.`
    }

    if (alert) {
        console.log(alertMessage);
    
        const command = new SendEmailCommand({
            Destination: {
              ToAddresses: ["kennethisom@gmail.com"],
            },
            Message: {
              Body: {
                Text: { Data: alertMessage },
              },
        
              Subject: { Data: alertMessage },
            },
            Source: "dustycursor@gmail.com",
          });

        try {
            let response = await ses.send(command);
            console.log('Email sent sucessfully');
            console.log(response);
            return response;
        }
        catch (error) {
            console.log('Email failed');
            console.log(error);
        }
        finally {
            console.log('Alert attempt complete');
        }
    } else {
        console.log("Nothing!");
    }

    return 1;
};