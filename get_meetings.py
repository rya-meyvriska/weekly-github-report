#!/usr/bin/env python3
import argparse
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

import pytz
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

# If modifying these scopes, delete the file token.json.
SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']

# Directory for credentials
CONFIG_DIR = Path.home() / '.config' / 'weekly-report'
CONFIG_DIR.mkdir(parents=True, exist_ok=True)
TOKEN_FILE = CONFIG_DIR / 'google_token.json'
CLIENT_SECRET_FILE = CONFIG_DIR / 'client_secret.json'  # User needs to provide this

def authenticate():
    creds = None
    # The file token.json stores the user's access and refresh tokens.
    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not CLIENT_SECRET_FILE.exists():
                print(f"Error: {CLIENT_SECRET_FILE} not found. Please download your OAuth 2.0 client secrets from Google Cloud Console and save as {CLIENT_SECRET_FILE}")
                sys.exit(1)
            flow = InstalledAppFlow.from_client_secrets_file(str(CLIENT_SECRET_FILE), SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
    return creds

def get_user_email(creds):
    service = build('oauth2', 'v2', credentials=creds)
    user_info = service.userinfo().get().execute()
    return user_info['email']

def get_meetings(start_date, end_date, user_email):
    creds = authenticate()
    service = build('calendar', 'v3', credentials=creds)

    # Convert dates to RFC3339
    start = datetime.fromisoformat(start_date).replace(tzinfo=pytz.UTC).isoformat()
    end = (datetime.fromisoformat(end_date) + timedelta(days=1)).replace(tzinfo=pytz.UTC).isoformat()  # Include end date

    events_result = service.events().list(calendarId='primary', timeMin=start, timeMax=end,
                                          singleEvents=True, orderBy='startTime').execute()
    events = events_result.get('items', [])

    meetings = []
    local_tz = pytz.timezone('UTC')  # Default to UTC, but could detect local

    for event in events:
        if event.get('status') == 'cancelled':
            continue

        attendees = event.get('attendees', [])
        my_attendee = None
        for attendee in attendees:
            if attendee.get('email') == user_email:
                my_attendee = attendee
                break
        if not my_attendee:
            continue  # Not invited

        # Extract details
        summary = event.get('summary', 'No Title')
        response_status = my_attendee.get('responseStatus', 'needsAction')
        if response_status == 'accepted':
            status = 'Attend'
        elif response_status == 'declined':
            status = 'Decline'
        else:
            status = 'No Respond'

        start_time = event['start']
        if 'dateTime' in start_time:
            start_dt = datetime.fromisoformat(start_time['dateTime'].replace('Z', '+00:00'))
            start_local = start_dt.astimezone(local_tz)
            date = start_local.strftime('%Y-%m-%d')
        else:
            # All-day
            date = start_time['date']

        meetings.append(f"- [{date}] [{status}] {summary}")

    return meetings

def main():
    parser = argparse.ArgumentParser(description='Get meetings from Google Calendar')
    parser.add_argument('--start', required=True, help='Start date YYYY-MM-DD')
    parser.add_argument('--end', required=True, help='End date YYYY-MM-DD')
    parser.add_argument('--auth', action='store_true', help='Run authentication')

    args = parser.parse_args()

    if args.auth:
        authenticate()
        print("Authentication complete. Token saved.")
        return

    creds = authenticate()
    user_email = get_user_email(creds)
    meetings = get_meetings(args.start, args.end, user_email)
    for meeting in meetings:
        print(meeting)

if __name__ == '__main__':
    main()