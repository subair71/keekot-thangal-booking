import {test} from 'node:test';
import assert from 'node:assert/strict';
import {noticeData,pushWebOptions} from '../src/notifications.js';

test('confirmation notice is addressed to booking owner with India visit time',()=>{
  const n=noticeData('booking-1','confirmed',{userId:'visitor-1',startAt:Date.parse('2030-01-10T04:30:00Z')});
  assert.equal(n.userId,'visitor-1');assert.equal(n.bookingId,'booking-1');
  assert.equal(n.title,'Booking confirmed');assert.equal(n.delivery,'pending');
  assert.match(n.body,/10:00/);assert.match(n.body,/10 Jan/);
  assert.equal(n.read,false);assert.equal(n.attempts,0);
});
test('push links and logo resolve under GitHub Pages base path',()=>{
  const options=pushWebOptions('notice-1','booking-1','https://example.com/keekot-thangal-booking');
  const link=new URL(options.fcmOptions.link);
  assert.equal(link.pathname,'/keekot-thangal-booking/');
  assert.equal(link.searchParams.get('route'),'booking');
  assert.equal(link.searchParams.get('bookingId'),'booking-1');
  assert.equal(options.notification.icon,'https://example.com/keekot-thangal-booking/icons/keekkott-logo-192.png');
});
test('push links also support root hosting',()=>{
  assert.equal(new URL(pushWebOptions('n','b','https://example.com/').fcmOptions.link).pathname,'/');
});
test('staff notices go to the creator account and never use a visitor contact as an account or SMS recipient',()=>{
  for(const kind of ['confirmed','cancelled','reminder']) {
    const n=noticeData('booking-2',kind,{userId:'creator',bookedByUid:'creator',bookingSource:'staff',visitorPhone:'+919876543210',startAt:Date.parse('2030-01-10T04:30:00Z')});
    assert.equal(n.userId,'creator');assert.equal(n.recipientRole,'booker');
    assert.match(n.body,/you booked for a visitor/);
    assert.doesNotMatch(n.body,/9876543210|Your.*visit/);
  }
});
