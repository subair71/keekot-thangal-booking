import {test} from 'node:test';
import assert from 'node:assert/strict';
import {validateContact, contactMail, contactMailbox} from '../src/contact.js';

const valid = {name: 'Visitor Name', email: 'visitor@example.com', phone: '+91 9876543210', subject: 'Visit enquiry', message: 'Can you help with my upcoming visit?'};
test('contact mail uses a fixed recipient and visitor reply-to', () => {
  const mail = contactMail(validateContact({...valid, to: 'other@example.com'}));
  assert.equal(mail.to, contactMailbox);
  assert.equal(mail.from.address, contactMailbox);
  assert.equal(mail.replyTo.address, valid.email);
  assert.ok(mail.text.includes(valid.message));
});
test('contact rejects header injection, invalid email and oversized messages', () => {
  for (const data of [{...valid, subject: 'Hello\r\nBcc: other@example.com'}, {...valid, email: 'invalid'}, {...valid, message: 'x'.repeat(3001)}, {...valid, phone: '<script>'}, null]) {
    assert.throws(() => validateContact(data));
  }
});
test('contact accepts Malayalam, multiline message and optional phone', () => {
  const data = validateContact({...valid, name: 'സന്ദർശകൻ', phone: '', message: 'സന്ദർശനത്തെക്കുറിച്ചുള്ള ചോദ്യം\nദയവായി മറുപടി നൽകുക.'});
  assert.equal(data.phone, '');
  assert.ok(data.message.includes('\n'));
});
