DB_URL=postgres://root:secret@localhost:5432/simple_bank?sslmode=disable
TEST_DB_URL=postgres://root:secret@localhost:5432/simple_bank_test?sslmode=disable

postgres:
	docker run --name postgres18 -p 5432:5432 \
	-e POSTGRES_USER=root \
	-e POSTGRES_PASSWORD=secret \
	-d postgres:18-alpine


psql:
	docker exec -it postgres18 psql -U root -d simple_bank

psqltest:
	docker exec -it postgres18 psql -U root -d simple_bank_test

countmain:
	docker exec -it postgres18 psql -U root -d simple_bank -c "SELECT count(*) FROM accounts;"

counttest:
	docker exec -it postgres18 psql -U root -d simple_bank_test -c "SELECT count(*) FROM accounts;"

createdb:
	docker exec -it postgres18 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres18 dropdb simple_bank

migrateup:
	migrate -path db/migration -database "$(DB_URL)" -verbose up

migratedown:
	migrate -path db/migration -database "$(DB_URL)" -verbose down

sqlc:
	sqlc generate

startdb:
	docker start postgres18

test:
	go test -count=1 ./db/sqlc -v -cover

testall:
	go test -count=1 ./... -v

testtransfer:
	go test -count=1 -run TestTransferTx ./db/sqlc -v

testtransferclean:
	$(MAKE) cleantest
	DB_SOURCE="$(TEST_DB_URL)" go test -count=1 -run TestTransferTx$ ./db/sqlc -v

createtestdb:
	docker exec -it postgres18 createdb --username=root --owner=root simple_bank_test

droptestdb:
	docker exec -it postgres18 dropdb simple_bank_test

migrateup_test:
	migrate -path db/migration -database "$(TEST_DB_URL)" -verbose up

migratedown_test:
	migrate -path db/migration -database "$(TEST_DB_URL)" -verbose down

cleantest:
	docker exec -it postgres18 psql -U root -d simple_bank_test -c "TRUNCATE TABLE entries, transfers, accounts RESTART IDENTITY CASCADE;"

testdb:
	DB_SOURCE="$(TEST_DB_URL)" go test -count=1 ./db/sqlc -v -cover

runtests:
	$(MAKE) cleantest
	$(MAKE) testdb

.PHONY: postgres createdb dropdb migrateup migratedown sqlc startdb
.PHONY: test testall testtransfer testtransferclean testdb runtests
.PHONY: createtestdb droptestdb migrateup_test migratedown_test cleantest
.PHONY: psql psqltest countmain counttest