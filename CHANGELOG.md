# Changelog

## 0.0.1

**Initial release of the package**

- Introduced a **centralized API service** with:
  - Unified `GET`, `POST`, `PUT`, `PATCH`, and `DELETE` request handling  
  - Built-in **error catching** (`DioException` & general exceptions)  
  - Custom **success and failure callbacks**  

- Added a **floating draggable debug overlay** for real-time API inspection  
  - View logs, request bodies, and responses directly in-app  
  - Includes **JSON tree view** and **color-highlighted JSON viewer**  
  - Expandable to a **full-screen log viewer**  

- Added **log filtering** (by method, status, or keyword)  

- Example project demonstrating integration with a **public REST API**  
