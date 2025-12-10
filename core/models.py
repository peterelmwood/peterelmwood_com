from django.db import models
from django.utils.text import slugify


class BlogPost(models.Model):
    """Blog post model for personal blog content."""

    title = models.CharField(max_length=200)
    slug = models.SlugField(max_length=200, unique=True)
    content = models.TextField()
    excerpt = models.TextField(blank=True)
    published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Blog Post"
        verbose_name_plural = "Blog Posts"

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            base_slug = slugify(self.title)
            self.slug = base_slug
            # Handle duplicate slugs by appending a counter
            # Fetch all matching slugs in a single query
            existing_slugs = set(
                BlogPost.objects.filter(
                    slug__startswith=base_slug
                ).exclude(pk=self.pk).values_list("slug", flat=True)
            )
            if existing_slugs:
                counter = 1
                while self.slug in existing_slugs:
                    self.slug = f"{base_slug}-{counter}"
                    counter += 1
        super().save(*args, **kwargs)


class Project(models.Model):
    """Portfolio project model."""

    title = models.CharField(max_length=200)
    slug = models.SlugField(max_length=200, unique=True)
    description = models.TextField()
    tech_stack = models.CharField(max_length=500, blank=True)
    github_url = models.URLField(blank=True)
    live_url = models.URLField(blank=True)
    featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Project"
        verbose_name_plural = "Projects"

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            base_slug = slugify(self.title)
            self.slug = base_slug
            # Handle duplicate slugs by appending a counter
            # Fetch all matching slugs in a single query
            existing_slugs = set(
                Project.objects.filter(
                    slug__startswith=base_slug
                ).exclude(pk=self.pk).values_list("slug", flat=True)
            )
            if existing_slugs:
                counter = 1
                while self.slug in existing_slugs:
                    self.slug = f"{base_slug}-{counter}"
                    counter += 1
        super().save(*args, **kwargs)
