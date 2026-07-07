const request = require('supertest');

jest.mock('mysql2/promise');
const mysql = require('mysql2/promise');

// Load app AFTER mock is set up so module.exports captures the mocked module
const app = require('../index');

afterEach(() => {
  jest.clearAllMocks();
});

describe('GET /health', () => {
  it('returns 200 and body OK', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.text).toBe('OK');
  });
});

describe('GET /', () => {
  it('returns 200 with status connected and db_time when DB succeeds', async () => {
    const mockConn = {
      query: jest.fn().mockResolvedValue([[
        { db_time: '2026-07-08T12:00:00.000Z', db_version: '8.0.32' }
      ]]),
      end: jest.fn().mockResolvedValue(undefined),
    };
    mysql.createConnection.mockResolvedValue(mockConn);

    const res = await request(app).get('/');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('connected');
    expect(res.body).toHaveProperty('db_time');
  });

  it('returns 500 with status db_error when DB throws', async () => {
    mysql.createConnection.mockRejectedValue(new Error('ECONNREFUSED'));

    const res = await request(app).get('/');

    expect(res.status).toBe(500);
    expect(res.body.status).toBe('db_error');
  });
});
