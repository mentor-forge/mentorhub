# Data Standards

## Tech Stack
- MongoDB Document Database
- [MongoDB Configurator utility](https://github.com/agile-learning-institute/mongodb_configurator) to package our Schema Configurations for deployment. 

## Standards
- All collection names are PascalCase, Singular. (TestRun not test_runs)
- All property names are snake case (first_name, street_address, etc.)
- Every collection should have the following properties
    - _id: This is a generated property but we should always be aware of it and represent it the schema. 
    - status: Status of the document - should include a "soft delete" indicator, typically an enum type.
    - name: This is a document name, should be human readable, typically of type Word, indexed for search.
    - description: This is a text description typically of type Sentence
    - created: A tracking breadcrumb of when the document was first created.
    - saved: A tracking breadcrumb of when the document was last saved. Note the collections that are write once read many may not have this property.