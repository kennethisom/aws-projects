import {handler} from './main';

test('test description', async () => {
    let response = await handler();
    expect(response).toBe(1);
})