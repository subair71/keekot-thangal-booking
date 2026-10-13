import {test} from 'node:test';
import assert from 'node:assert/strict';
import {notificationLinks} from '../src/notification_links.js';
test('notification destinations preserve root and project-path hosting',()=>{
  assert.deepEqual(notificationLinks('https://example.web.app','abc'),{
    link:'https://example.web.app/booking/abc',icon:'https://example.web.app/icons/Icon-192.png'});
  for(const base of ['https://subair71.github.io/keekot-thangal-booking','https://subair71.github.io/keekot-thangal-booking/']) {
    assert.deepEqual(notificationLinks(base,'abc'),{
      link:'https://subair71.github.io/keekot-thangal-booking/booking/abc',
      icon:'https://subair71.github.io/keekot-thangal-booking/icons/Icon-192.png'});
  }
  assert.equal(notificationLinks(undefined,'abc'),undefined);
  for(const base of ['http://example.com','https://user:password@example.com','https://example.com?x=1','https://example.com#x']) {
    assert.throws(()=>notificationLinks(base,'abc'));
  }
});
