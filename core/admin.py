from django.contrib import admin

from .models import BlogPost, Project


@admin.register(BlogPost)
class BlogPostAdmin(admin.ModelAdmin):
    list_display = ["title", "published", "created_at", "published_at"]
    list_filter = ["published", "created_at"]
    search_fields = ["title", "content"]
    prepopulated_fields = {"slug": ("title",)}
    date_hierarchy = "created_at"


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ["title", "featured", "created_at"]
    list_filter = ["featured", "created_at"]
    search_fields = ["title", "description"]
    prepopulated_fields = {"slug": ("title",)}
