# Website Development Issues

This document contains detailed descriptions for GitHub issues to be created for the peterelmwood.com website development project.

---

## Preliminary Issues

### 1. Setup VM

**Title:** Setup Virtual Machine Environment

**Description:**
Set up a virtual machine to host the Django web application.

**Implementation Details:**
1. **Choose a cloud provider** (e.g., GCP Compute Engine, AWS EC2, DigitalOcean Droplet, or Azure VM)
2. **Provision the VM** with appropriate specifications:
   - Recommended: 2 vCPUs, 4GB RAM minimum for development
   - Ubuntu 22.04 LTS or Debian 12 as the base OS
   - At least 20GB SSD storage
3. **Configure networking:**
   - Set up firewall rules to allow HTTP (80), HTTPS (443), and SSH (22)
   - Assign a static/elastic IP address
   - Configure DNS if a domain is available
4. **Install required software:**
   - Python 3.11+
   - PostgreSQL client libraries
   - Docker and Docker Compose (if using containerized deployment)
   - Nginx as a reverse proxy
5. **Set up SSH access:**
   - Configure SSH keys for secure access
   - Disable password authentication
   - Set up a non-root user with sudo privileges

**Acceptance Criteria:**
- [ ] VM is provisioned and running
- [ ] SSH access is configured and working
- [ ] Required ports are open in the firewall
- [ ] Base software packages are installed

---

### 2. Ensure We Can Connect

**Title:** Verify VM Connectivity and Network Configuration

**Description:**
Verify that the VM is accessible from the internet and all networking is properly configured.

**Implementation Details:**
1. **Test SSH connectivity:**
   ```bash
   ssh -i /path/to/key username@vm-ip-address
   ```
2. **Verify DNS resolution** (if domain is configured):
   ```bash
   nslookup yourdomain.com
   dig yourdomain.com
   ```
3. **Test HTTP/HTTPS ports:**
   ```bash
   # From local machine
   curl -I http://vm-ip-address
   telnet vm-ip-address 80
   ```
4. **Configure SSL/TLS:**
   - Set up Let's Encrypt with Certbot for free SSL certificates
   - Configure automatic certificate renewal
5. **Set up monitoring:**
   - Install basic monitoring tools (e.g., htop, netstat)
   - Consider setting up uptime monitoring (e.g., UptimeRobot, GCP monitoring)

**Acceptance Criteria:**
- [ ] SSH connection works from development machine
- [ ] HTTP requests reach the server
- [ ] HTTPS is configured with valid SSL certificate
- [ ] DNS resolves correctly to VM IP (if applicable)

---

### 3. Setup Django Webserver

**Title:** Configure and Deploy Django Web Server

**Description:**
Set up the Django application with Gunicorn/Uvicorn as the application server and Nginx as the reverse proxy.

**Implementation Details:**
1. **Clone the repository on the VM:**
   ```bash
   git clone https://github.com/peterelmwood/peterelmwood_com.git
   cd peterelmwood_com
   ```
2. **Install dependencies using uv:**
   ```bash
   pip install uv
   uv sync
   ```
3. **Configure environment variables:**
   - Copy `.env.example` to `.env`
   - Set `SECRET_KEY` (generate a secure key)
   - Set `DEBUG=False` for production
   - Configure `ALLOWED_HOSTS` with domain/IP
   - Set `DATABASE_URL` for PostgreSQL connection
4. **Set up Gunicorn/Uvicorn as the ASGI server:**
   ```bash
   # For ASGI (async support)
   uv run uvicorn config.asgi:application --host 0.0.0.0 --port 8000
   ```
5. **Configure systemd service:**
   ```ini
   [Unit]
   Description=Django ASGI Server
   After=network.target

   [Service]
   User=www-data
   WorkingDirectory=/path/to/peterelmwood_com
   ExecStart=/path/to/uv run uvicorn config.asgi:application --host 127.0.0.1 --port 8000
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```
6. **Configure Nginx as reverse proxy:**
   ```nginx
   server {
       listen 80;
       server_name yourdomain.com;

       location / {
           proxy_pass http://127.0.0.1:8000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }

       location /static/ {
           alias /path/to/staticfiles/;
       }
   }
   ```
7. **Collect static files:**
   ```bash
   uv run python manage.py collectstatic
   ```

**Acceptance Criteria:**
- [ ] Django application runs with Gunicorn/Uvicorn
- [ ] Nginx is configured as reverse proxy
- [ ] Static files are served correctly
- [ ] Application is accessible via domain/IP

---

### 4. Ensure Connection to the Database

**Title:** Configure and Verify PostgreSQL Database Connection

**Description:**
Set up PostgreSQL database and ensure the Django application can connect to it.

**Implementation Details:**
1. **Set up PostgreSQL:**
   - Option A: Install locally on VM
     ```bash
     sudo apt install postgresql postgresql-contrib
     ```
   - Option B: Use managed database (GCP Cloud SQL, AWS RDS, etc.)
   - Option C: Use Docker Compose (as defined in the repo)
     ```bash
     docker compose up -d db
     ```
2. **Create database and user:**
   ```sql
   CREATE DATABASE peterelmwood_com;
   CREATE USER django_user WITH PASSWORD 'secure_password';
   GRANT ALL PRIVILEGES ON DATABASE peterelmwood_com TO django_user;
   ```
3. **Configure DATABASE_URL:**
   ```
   DATABASE_URL=postgres://django_user:secure_password@localhost:5432/peterelmwood_com
   ```
4. **Test connection:**
   ```bash
   uv run python manage.py check --database default
   uv run python manage.py dbshell
   ```
5. **Run migrations:**
   ```bash
   uv run python manage.py migrate
   ```
6. **Verify database tables:**
   ```bash
   uv run python manage.py showmigrations
   ```

**Acceptance Criteria:**
- [ ] PostgreSQL is installed and running
- [ ] Django can connect to the database
- [ ] All migrations run successfully
- [ ] Database tables are created correctly

---

## Functional Issues

### 5. Create Sample Text Data

**Title:** Create Sample Text Data Generator with Predetermined Substrings

**Description:**
Create sample text data of M-to-N characters in length, with specific instances containing predetermined substrings for testing full-text search functionality.

**Implementation Details:**
1. **Create a Django management command:**
   ```python
   # apps/core/management/commands/generate_sample_data.py
   from django.core.management.base import BaseCommand
   import random
   import string

   class Command(BaseCommand):
       help = 'Generate sample text data with predetermined substrings'

       def add_arguments(self, parser):
           parser.add_argument('--count', type=int, default=1000)
           parser.add_argument('--min-length', type=int, default=100)
           parser.add_argument('--max-length', type=int, default=500)

       def handle(self, *args, **options):
           # Implementation here
           pass
   ```
2. **Define predetermined substrings:**
   ```python
   SUBSTRINGS = [
       "Django",
       "PostgreSQL",
       "full-text search",
       "database optimization",
       "web development",
   ]
   ```
3. **Generate random text with embedded substrings:**
   ```python
   def generate_text(min_len, max_len, substrings):
       length = random.randint(min_len, max_len)
       # Generate base text
       words = [''.join(random.choices(string.ascii_lowercase, k=random.randint(3, 10)))
                for _ in range(length // 5)]
       text = ' '.join(words)
       # Insert predetermined substrings at random positions
       for substring in random.sample(substrings, k=random.randint(0, len(substrings))):
           pos = random.randint(0, len(text))
           text = text[:pos] + ' ' + substring + ' ' + text[pos:]
       return text[:max_len]
   ```
4. **Option to load from files:**
   - Create fixture files in `fixtures/` directory
   - Use `loaddata` command for batch imports
5. **Batch insert for performance:**
   ```python
   from django.db import transaction
   
   with transaction.atomic():
       Model.objects.bulk_create(instances, batch_size=1000)
   ```

**Acceptance Criteria:**
- [ ] Management command generates configurable sample data
- [ ] Data includes predetermined substrings at known positions
- [ ] Batch insertion is efficient for large datasets
- [ ] Can generate data via command line or fixture files

---

### 6. Create Database Tables for Sample Data

**Title:** Create Database Models with Two Tables/Columns for Full-Text Search Comparison

**Description:**
Create two different tables (or two different columns in one table) where the sample data will be inserted - one for full-text search and one without.

**Implementation Details:**
1. **Create Django models:**
   ```python
   # apps/search/models.py
   from django.db import models
   from django.contrib.postgres.indexes import GinIndex
   from django.contrib.postgres.search import SearchVectorField

   class TextDataWithSearch(models.Model):
       """Table with full-text search enabled"""
       content = models.TextField()
       search_vector = SearchVectorField(null=True)  # For FTS
       created_at = models.DateTimeField(auto_now_add=True)

       class Meta:
           indexes = [
               GinIndex(fields=['search_vector']),
           ]

   class TextDataWithoutSearch(models.Model):
       """Table without full-text search (for comparison)"""
       content = models.TextField()
       created_at = models.DateTimeField(auto_now_add=True)
   ```
2. **Alternative: Single table with two columns:**
   ```python
   class TextData(models.Model):
       content_fts = models.TextField()  # Full-text search enabled
       content_plain = models.TextField()  # No FTS
       search_vector = SearchVectorField(null=True)
   ```
3. **Create and run migrations:**
   ```bash
   uv run python manage.py makemigrations search
   uv run python manage.py migrate
   ```
4. **Verify table structure:**
   ```bash
   uv run python manage.py dbshell
   \d search_textdatawithsearch
   ```

**Acceptance Criteria:**
- [ ] Models are defined with appropriate fields
- [ ] Migrations are created and applied
- [ ] Tables exist in the database
- [ ] Indexes are properly configured

---

### 7. Enable Full Text Search

**Title:** Enable PostgreSQL Full-Text Search on One Table

**Description:**
Enable full-text search capabilities in PostgreSQL for one table while keeping the other table without FTS for comparison testing.

**Implementation Details:**
1. **Enable pg_trgm extension for similarity search:**
   ```python
   # In a migration
   from django.contrib.postgres.operations import TrigramExtension
   
   class Migration(migrations.Migration):
       operations = [
           TrigramExtension(),
       ]
   ```
2. **Configure SearchVector for automatic updates:**
   ```python
   from django.contrib.postgres.search import SearchVector
   from django.db.models.signals import post_save
   from django.dispatch import receiver

   @receiver(post_save, sender=TextDataWithSearch)
   def update_search_vector(sender, instance, **kwargs):
       TextDataWithSearch.objects.filter(pk=instance.pk).update(
           search_vector=SearchVector('content')
       )
   ```
3. **Create database trigger for real-time updates:**
   ```sql
   CREATE TRIGGER search_vector_update
   BEFORE INSERT OR UPDATE ON search_textdatawithsearch
   FOR EACH ROW EXECUTE FUNCTION
   tsvector_update_trigger(search_vector, 'pg_catalog.english', content);
   ```
4. **Add GIN index for performance:**
   ```python
   class Meta:
       indexes = [
           GinIndex(fields=['search_vector']),
           GinIndex(
               name='content_trgm_idx',
               fields=['content'],
               opclasses=['gin_trgm_ops'],
           ),
       ]
   ```
5. **Populate search vectors for existing data:**
   ```python
   TextDataWithSearch.objects.update(
       search_vector=SearchVector('content')
   )
   ```

**Acceptance Criteria:**
- [ ] SearchVectorField is populated on insert/update
- [ ] GIN index is created for fast lookups
- [ ] FTS works on TextDataWithSearch table
- [ ] TextDataWithoutSearch has no FTS overhead

---

### 8. Perform Substring Matching Queries

**Title:** Implement Substring Matching Queries with Performance Comparison

**Description:**
Perform queries for matching substrings using both full-text search and regular LIKE queries, comparing performance.

**Implementation Details:**
1. **Create query utilities:**
   ```python
   # apps/search/queries.py
   from django.contrib.postgres.search import SearchQuery, SearchRank
   from django.db.models import F
   import time

   def fts_search(query_text):
       """Full-text search query"""
       search_query = SearchQuery(query_text)
       return TextDataWithSearch.objects.annotate(
           rank=SearchRank(F('search_vector'), search_query)
       ).filter(search_vector=search_query).order_by('-rank')

   def like_search(query_text):
       """Traditional LIKE query"""
       return TextDataWithoutSearch.objects.filter(
           content__icontains=query_text
       )

   def benchmark_queries(query_text, iterations=100):
       """Compare performance between FTS and LIKE"""
       # FTS benchmark
       start = time.perf_counter()
       for _ in range(iterations):
           list(fts_search(query_text))
       fts_time = time.perf_counter() - start

       # LIKE benchmark
       start = time.perf_counter()
       for _ in range(iterations):
           list(like_search(query_text))
       like_time = time.perf_counter() - start

       return {
           'fts_time': fts_time,
           'like_time': like_time,
           'speedup': like_time / fts_time
       }
   ```
2. **Create API endpoints for search:**
   ```python
   # apps/search/views.py
   from rest_framework.views import APIView
   from rest_framework.response import Response

   class SearchView(APIView):
       def get(self, request):
           query = request.query_params.get('q', '')
           method = request.query_params.get('method', 'fts')
           
           if method == 'fts':
               results = fts_search(query)
           else:
               results = like_search(query)
           
           return Response({'results': list(results.values())})
   ```
3. **Create management command for benchmarking:**
   ```bash
   uv run python manage.py benchmark_search "Django" --iterations 1000
   ```
4. **Log query execution plans:**
   ```python
   from django.db import connection
   
   def explain_query(queryset):
       sql, params = queryset.query.sql_with_params()
       with connection.cursor() as cursor:
           cursor.execute(f"EXPLAIN ANALYZE {sql}", params)
           return cursor.fetchall()
   ```

**Acceptance Criteria:**
- [ ] FTS queries return ranked results
- [ ] LIKE queries work for comparison
- [ ] Benchmark utility measures performance difference
- [ ] API endpoint exposes search functionality

---

### 9. Perform DBMS-Side String Replacement

**Title:** Implement Database-Side String Replacement by Index

**Description:**
Perform DBMS-side string replacement for matches by index, allowing efficient bulk updates without loading data into Python.

**Implementation Details:**
1. **Use PostgreSQL's regexp_replace:**
   ```python
   from django.db.models import F, Value
   from django.db.models.functions import Replace

   # Simple replacement
   TextDataWithSearch.objects.filter(
       content__contains='old_text'
   ).update(
       content=Replace(F('content'), Value('old_text'), Value('new_text'))
   )
   ```
2. **Create custom database function for index-based replacement:**
   ```python
   from django.db.models import Func

   class SubstringReplace(Func):
       """Replace substring at specific position"""
       function = 'OVERLAY'
       template = "%(function)s(%(expressions)s PLACING %(replacement)s FROM %(start)s FOR %(length)s)"

       def __init__(self, expression, replacement, start, length, **extra):
           super().__init__(
               expression,
               replacement=replacement,
               start=start,
               length=length,
               **extra
           )
   ```
3. **Raw SQL for complex replacements:**
   ```python
   from django.db import connection

   # IMPORTANT: Use a whitelist approach or quote_name() to prevent SQL injection
   ALLOWED_TABLES = {'search_textdatawithsearch', 'search_textdatawithoutsearch'}
   ALLOWED_COLUMNS = {'content'}

   def replace_by_index(table, column, start_idx, length, replacement):
       """Replace text at specific index position
       
       Note: table and column must be validated against whitelist to prevent SQL injection
       """
       if table not in ALLOWED_TABLES or column not in ALLOWED_COLUMNS:
           raise ValueError("Invalid table or column name")
       
       # Use quote_name for safe identifier quoting
       quoted_table = connection.ops.quote_name(table)
       quoted_column = connection.ops.quote_name(column)
       
       sql = f"""
       UPDATE {quoted_table}
       SET {quoted_column} = OVERLAY({quoted_column} PLACING %s FROM %s FOR %s)
       """
       with connection.cursor() as cursor:
           cursor.execute(sql, [replacement, start_idx, length])
           return cursor.rowcount
   ```
4. **Batch replacement with tracking:**
   ```python
   def batch_replace_matches(pattern, replacement, batch_size=1000):
       """Replace all matches in batches"""
       total_replaced = 0
       while True:
           with transaction.atomic():
               updated = TextDataWithSearch.objects.filter(
                   content__regex=pattern
               )[:batch_size].update(
                   content=Replace(F('content'), Value(pattern), Value(replacement))
               )
               if updated == 0:
                   break
               total_replaced += updated
       return total_replaced
   ```
5. **Create API endpoint for replacements:**
   ```python
   class ReplaceView(APIView):
       def post(self, request):
           pattern = request.data.get('pattern')
           replacement = request.data.get('replacement')
           method = request.data.get('method', 'simple')
           
           if method == 'by_index':
               start = request.data.get('start')
               length = request.data.get('length')
               # Using TextDataWithSearch table and content column
               count = replace_by_index(
                   'search_textdatawithsearch', 
                   'content', 
                   start, 
                   length, 
                   replacement
               )
           else:
               count = TextDataWithSearch.objects.filter(
                   content__contains=pattern
               ).update(content=Replace(F('content'), Value(pattern), Value(replacement)))
           
           return Response({'replaced_count': count})
   ```

**Acceptance Criteria:**
- [ ] Simple string replacement works via Django ORM
- [ ] Index-based replacement is implemented using PostgreSQL OVERLAY
- [ ] Batch replacements are efficient and don't lock the database
- [ ] API endpoint allows triggering replacements
- [ ] All operations happen server-side without loading data to Python

---

## Summary

| Issue # | Title | Category |
|---------|-------|----------|
| 1 | Setup Virtual Machine Environment | Preliminary |
| 2 | Verify VM Connectivity and Network Configuration | Preliminary |
| 3 | Configure and Deploy Django Web Server | Preliminary |
| 4 | Configure and Verify PostgreSQL Database Connection | Preliminary |
| 5 | Create Sample Text Data Generator | Functional |
| 6 | Create Database Models for Full-Text Search Comparison | Functional |
| 7 | Enable PostgreSQL Full-Text Search | Functional |
| 8 | Implement Substring Matching Queries | Functional |
| 9 | Implement Database-Side String Replacement | Functional |

Each issue above contains detailed implementation steps and acceptance criteria that can be used to create GitHub issues manually.
