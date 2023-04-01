# Coding Exercise: Data Storage API

Implement a small HTTP service to store objects organized by repository.
Clients of this service should be able to GET, PUT, and DELETE objects.

## General Requirements

- The service should identify objects by their content. This means that two objects with the same content should be considered identical, and only one such object should be stored per repository. Objects with the same content can exist in different repositories.
- The service should listen on port `8282`.
- The included tests should pass and not be modified. Adding additional tests is encouraged.
- The service must implement the API as described below.
- The data can be persisted in memory, on disk, or wherever you like.
- Do not include any extra dependencies.

## API

### Upload an Object

```
PUT /data/{repository}
```

#### Response

```
Status: 201 Created
{
  "oid": "2845f5a412dbdfacf95193f296dd0f5b2a16920da5a7ffa4c5832f223b03de96",
  "size": 1234
}
```

### Download an Object

```
GET /data/{repository}/{objectID}
```

#### Response

```
Status: 200 OK
{object data}
```

Objects that are not on the server will return a `404 Not Found`.

### Delete an Object

```
DELETE /data/{repository}/{objectID}
```

#### Response

```
Status: 200 OK
```

## Getting started and Testing

In server-rack.rb you'll find a naive first draft of the answer to the exercise written for you. Please improve this draft so that it passes the test written in test.rb. You might need to install rack:

```
gem install rack rack-test
```

You can test that this works by running:

```
ruby test.rb
```
