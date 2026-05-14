CREATE TABLE web_logs (
    timestamp DateTime,
    user_id UInt64
    url LowCardinality(String), --String
    response_time UInt32,
    status_code LowCardinality(UInt16) --UInt16
) ENGINE = MergeTree()
ORDER BY (timestamp, user_id)
PARTITION BY toYYYYMM(timestamp);


--генератор для CSV
/*
import csv
import random
from datetime import datetime, timedelta
import pandas as pd

start_date = datetime(2025, 1, 1, 0, 0, 0)
num_records = 10000
users = list(range(1, 101))  # 100 пользователей
urls = ['/home', '/about', '/contact', '/api/users', '/api/products', '/login', '/logout']
status_codes = [200, 200, 200, 200, 201, 304, 400, 404, 500]

data = []
for i in range(num_records):
    timestamp = start_date + timedelta(seconds=random.randint(0, 86400 * 30))
    user_id = random.choice(users)
    url = random.choice(urls)
    response_time = random.randint(10, 2000)  # мс
    status_code = random.choices(status_codes, weights=[0.7, 0.1, 0.05, 0.05, 0.02, 0.03, 0.02, 0.02, 0.01])[0]
    data.append([timestamp, user_id, url, response_time, status_code])

df = pd.DataFrame(data, columns=['timestamp', 'user_id', 'url', 'response_time', 'status_code'])
df.to_csv('web_logs.csv', index=False)
print(f"Сгенерировано {num_records} записей в web_logs.csv")
*/

--    ▪️ Найдите общее количество запросов за каждый день.
SELECT
    toDate(timestamp) AS day,
    count() AS total_requests
FROM web_logs
GROUP BY day
ORDER BY day ASC;

--     ▪️ Определите среднее время ответа для каждого URL.
SELECT
    url,
    avg(response_time) AS avg_response_time_ms,
FROM web_logs
GROUP BY url
ORDER BY avg_response_time_ms DESC;

--     ▪️ Подсчитайте количество запросов с ошибками (например, статус-коды 4xx и 5xx).
SELECT
    status_code,
    count() AS count
FROM web_logs
WHERE status_code >= 400
GROUP BY status_code
ORDER BY count DESC;

--     ▪️ Найдите топ-10 пользователей по количеству запросов.
SELECT
    user_id,
    count() AS request_count
FROM web_logs
GROUP BY user_id
LIMIT 10 BY request_count;


-- добавление индекса
ALTER TABLE web_logs ADD INDEX idx_url url TYPE bloom_filter GRANULARITY 4;


--Документация
/*
Таблица предназначена для хранения слогов HTTP-запросов к веб-серверу. 
Позволяет эффективно анализировать пользовательскую активность, временные ряды ответов сервера и коды ответов.

Движок MergeTree обеспечивает быструю вставку больших пачек данных, эффективное хранение со сжатием, управление партициями и порядком данных.

Ключ сортировки: (timestamp, user_id)
Партиционирование: toYYYYMM(timestamp) данные разбиваются на партиции по месяцам

LowCardinality для url и status_code — уменьшает потребление памяти и диска, заменяя повторяющиеся значения на словари.

*/